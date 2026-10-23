import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

def parse_mwb(mwb_path: Path) -> ET.Element:
    with zipfile.ZipFile(mwb_path, 'r') as z:
        # The XML model is stored under the name 'document.mwb.xml'
        with z.open('document.mwb.xml') as f:
            data = f.read()
    return ET.fromstring(data)

def get_text(elem, key, default=None):
    child = elem.find(key)
    return child.text if child is not None else default

def generate_sql(root: ET.Element) -> str:
    sql_statements = []
    # Navigate to the physical model -> catalog -> schemata -> tables
    # The structure is workbench > physical > Model > catalog > schemata > tables
    for physical_model in root.findall('.//workbench.physical.Model'):
        catalog = physical_model.find('.//db.mysql.Catalog')
        if catalog is None:
            continue
        for schema in catalog.findall('.//db.mysql.Schema'):
            schema_name = get_text(schema.find('.//value[@key="name"]'), '.', '')
            # Tables
            for tbl in schema.findall('.//db.mysql.Table'):
                table_name = get_text(tbl.find('.//value[@key="name"]'), '.')
                if not table_name:
                    continue
                cols_sql = []
                pk_cols = []
                # Columns
                for col in tbl.findall('.//db.mysql.Column'):
                    col_name = get_text(col.find('.//value[@key="name"]'), '.')
                    datatype_elem = col.find('.//link[@key="simpleType"]')
                    if datatype_elem is not None:
                        datatype = datatype_elem.text.split('.')[-1]
                    else:
                        datatype = 'VARCHAR(255)'
                    # length / precision
                    length = col.find('.//value[@key="length"]')
                    if length is not None and length.text and length.text != '-1':
                        datatype += f'({length.text})'
                    # NOT NULL
                    is_not_null = col.find('.//value[@key="isNotNull"]')
                    null_sql = ' NOT NULL' if is_not_null is not None and is_not_null.text == '1' else ''
                    # Default
                    default_val_elem = col.find('.//value[@key="defaultValue"]')
                    default_sql = ''
                    if default_val_elem is not None and default_val_elem.text not in (None, '', 'NULL'):
                        default_sql = f" DEFAULT '{default_val_elem.text}'"
                    cols_sql.append(f"  `{col_name}` {datatype}{null_sql}{default_sql}")
                    # Primary key detection: look for primary index later
                # Primary key and indexes
                pk_stmt = ''
                for idx in tbl.findall('.//db.mysql.Index'):
                    idx_name = get_text(idx.find('.//value[@key="name"]'), '.')
                    if idx_name == 'PRIMARY':
                        pk_cols = []
                        for idxcol in idx.findall('.//db.mysql.IndexColumn'):
                            col_ref = idxcol.find('.//link[@key="referencedColumn"]')
                            if col_ref is not None:
                                col_id = col_ref.text.strip('{}')
                                # Find column by id
                                col_elem = tbl.find(f".//db.mysql.Column[@id='{{{col_id}}}']")
                                if col_elem is not None:
                                    col_name = get_text(col_elem.find('.//value[@key="name"]'), '.')
                                    pk_cols.append(f'`{col_name}`')
                        if pk_cols:
                            pk_stmt = f",\n  PRIMARY KEY ({', '.join(pk_cols)})"
                create_stmt = f"CREATE TABLE `{table_name}` (\n{',\n'.join(cols_sql)}{pk_stmt}\n) ENGINE=InnoDB;"
                sql_statements.append(create_stmt)
    return '\n\n'.join(sql_statements)

def main():
    if len(sys.argv) != 2:
        print('Usage: python export_mwb_to_sql.py <path_to_mwb>', file=sys.stderr)
        sys.exit(1)
    mwb_path = Path(sys.argv[1])
    if not mwb_path.is_file():
        print(f'File not found: {mwb_path}', file=sys.stderr)
        sys.exit(1)
    root = parse_mwb(mwb_path)
    sql = generate_sql(root)
    print(sql)

if __name__ == '__main__':
    main()
