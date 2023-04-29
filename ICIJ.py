import requests
import zipfile
import re
from datetime import datetime
import csv
from file_handling import sql_cnxn


ICIJ_ZIPFILE_URL = "https://offshoreleaks-data.icij.org/offshoreleaks/csv/full-oldb.LATEST.zip"


YMD_DATE_RE = re.compile("^\d{4}\-\d{2}\-\d{2}$")
DMY_DATE_RE = re.compile("^\d{2}\-\w{3}\-\d{4}$")


def format_date_str(date_str):
    if date_str != '':
        if DMY_DATE_RE.search(date_str) is not None:
            return datetime.strptime(date_str, "%d-%b-%Y")
        elif YMD_DATE_RE.search(date_str) is not None:
            return datetime.strptime(date_str, "%Y-%m-%d")
    return date_str


def format_relationship_line(line):
    insert_line = line[0:4] + line[5:]
    insert_line[4] = format_date_str(insert_line[4])
    insert_line[5] = format_date_str(insert_line[5])
    return insert_line


def format_entity_line(line):
    for i in (9, 10, 11, 12):
        line[i] = format_date_str(line[i])
    return line


def format_other_line(line):
    for i in (3, 4, 5):
        line[i] = format_date_str(line[i])
    return line


def return_value(value):
    return value


def delete_from_table(table_name):
    with sql_cnxn() as cnxn:
        crsr = cnxn.cursor()
        crsr.execute("delete from " + table_name)
        cnxn.commit()


def add_icij_data(sql_quer, line_function, filename, pre_execution_function=None, pre_execution_args=[]):
    if pre_execution_function is not None:
        pre_execution_function(*pre_execution_args)
    with sql_cnxn() as cnxn:
        crsr = cnxn.cursor()
        with open(filename, 'r', encoding="utf-8", newline='') as rf:
            reader = csv.reader(rf, delimiter=",", quotechar='"')
            line = reader.__next__()
            line_group = []
            for i, line in enumerate(reader):
                if i % 300000 == 0:
                    crsr.executemany(sql_quer, line_group)
                    line_group = []
                insert_line = line_function(line)  # ignore status: redundant column
                line_group.append(insert_line)
        crsr.executemany(sql_quer, line_group)
        cnxn.commit()


insert_relationship = (
    "insert into ICIJRelationships (node_id_start, node_id_end, rel_type, link, start_date, "
    "end_date, sourceID) values (?, ?, ?, ?, ?, ?, ?)"
)
insert_entity = (
     "insert into ICIJEntities (node_id, name, original_name, former_name, jurisdiction, jurisdiction_description, "
     "company_type, address, internal_id, incorporation_date, inactivation_date, struck_off_date, dorm_date, status, "
     "service_provider, ibcRUC, country_codes, countries, sourceID, valid_until, note) "
     "values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) on conflict (node_id) do update set "
     "name=excluded.name, original_name=excluded.original_name, former_name=excluded.former_name, "
     "jurisdiction=excluded.jurisdiction, jurisdiction_description=excluded.jurisdiction_description, "
     "company_type=excluded.company_type, address=excluded.address, internal_id=excluded.internal_id, "
     "incorporation_date=excluded.incorporation_date, inactivation_date=excluded.inactivation_date, "
     "struck_off_date=excluded.struck_off_date, dorm_date=excluded.dorm_date, status=excluded.status, "
     "service_provider=excluded.service_provider, ibcRUC=excluded.ibcRUC, country_codes=excluded.country_codes, "
     "countries=excluded.countries, sourceID=excluded.sourceID, valid_until=excluded.valid_until, note=excluded.note"
)
insert_officers = (
    "insert into ICIJOfficers (node_id, name, countries, country_codes, sourceID, valid_until, note) "
    "values (?, ?, ?, ?, ?, ?, ?) on conflict (node_id) do update set name=excluded.name, "
    "countries=excluded.countries, country_codes=excluded.country_codes, sourceID=excluded.sourceID, "
    "valid_until=excluded.valid_until, note=excluded.note"
)
insert_intermediaries = (
    "insert into ICIJIntermediaries (node_id, name, status, internal_id, address, countries, country_codes, sourceID, "
    "valid_until, note) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) on conflict (node_id) do update set name=excluded.name, "
    "status=excluded.status, internal_id=excluded.internal_id, address=excluded.address, countries=excluded.countries, "
    "country_codes=excluded.country_codes, sourceID=excluded.sourceID, valid_until=excluded.valid_until, "
    "note=excluded.note"
)
insert_addresses = (
    "insert into ICIJAddresses (node_id, address, name, countries, country_codes, sourceID, valid_until, note) "
    "values (?, ?, ?, ?, ?, ?, ?, ?) on conflict (node_id) do update set address=excluded.address, name=excluded.name, "
    "countries=excluded.countries, country_codes=excluded.country_codes, sourceID=excluded.sourceID, "
    "valid_until=excluded.valid_until, note=excluded.note"
)
insert_others = (
    "insert into ICIJOthers (node_id, name, type, incorporation_date, struck_off_date, closed_date, "
    "jurisdiction, jurisdiction_description, countries, country_codes, sourceID, valid_until, note) "
    "values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) on conflict (node_id) do update set name=excluded.name, "
    "type=excluded.type, incorporation_date=excluded.incorporation_date, struck_off_date=excluded.struck_off_date, "
    "closed_date=excluded.closed_date, jurisdiction=excluded.jurisdiction, "
    "jurisdiction_description=excluded.jurisdiction_description, countries=excluded.countries, "
    "country_codes=excluded.country_codes, sourceID=excluded.sourceID, valid_until=excluded.valid_until, "
    "note=excluded.note"
)


def get_data():
    print("Downloading data from the ICIJ at '%s'..." % (ICIJ_ZIPFILE_URL,))
    r = requests.get(ICIJ_ZIPFILE_URL)
    with open("icij-data.zip", 'wb') as wf:
        wf.write(r.content)
    del r
    print("Extracting files...")
    with zipfile.ZipFile("icij-data.zip", 'r') as zp:
        zp.extractall("icij-data")
    print("Building relationships table...")
    add_icij_data(insert_relationship, format_relationship_line, "icij-data/relationships.csv",
                  pre_execution_function=delete_from_table, pre_execution_args=["ICIJRelationships"])
    print("Building entities table...")
    add_icij_data(insert_entity, format_entity_line, "icij-data/nodes-entities.csv")
    print("Building officers table...")
    add_icij_data(insert_officers, return_value, "icij-data/nodes-officers.csv")
    print("Building intermediaries table...")
    add_icij_data(insert_intermediaries, return_value, "icij-data/nodes-intermediaries.csv")
    print("Building addresses table...")
    add_icij_data(insert_addresses, return_value, "icij-data/nodes-addresses.csv")
    print("Building others table...")
    add_icij_data(insert_others, format_other_line, "icij-data/nodes-others.csv")
    print("Done!")


def foo(strobj, pk):
    test_re = re.compile("into (\w+) \((.*?)\)")
    matches = test_re.search(strobj)
    tbl = matches.group(1)
    columns = matches.group(2).split(', ')
    return ("insert into %s (%s) values (%s) on conflict (%s) do update set %s" %
            (tbl, ', '.join(columns), ', '.join(['?' for _ in columns]), pk,
             ', '.join(["%s=excluded.%s" % (x, x) for x in columns if x != pk])))

test = (
    "insert into UKSanctionsList (LastUpdated, DateDesignated, UniqueID, OFSIGroupID, UNReferenceNumber, RegimeName, "
    "IndividualEntityShip, DesignationSource, SanctionsImposed, OtherInformation, UKStatementofReasons, ArmsEmbargo, "
    "AssetFreeze, CharteringOfShips, ClosureOfRepresentativeOffices, CrewServicingOfShipsAndAircraft, Deflag, "
    "PreventionOfBusinessArrangements, PreventionOfCharteringOfShips, PreventionOfCharteringOfShipsAndAircraft, "
    "ProhibitionOfPortEntry, TargetedArmsEmbargo, TechnicalAssistanceRelatedToAircraft, TravelBan, "
    "TrustServicesSanctions) "
    "values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
)
# print(', '.join(["LastUpdated", "DateDesignated", "UniqueID", "OFSIGroupID",
#                                "UNReferenceNumber", "RegimeName", "IndividualEntityShip", "DesignationSource",
#                                "SanctionsImposed", "OtherInformation", "UKStatementofReasons"] +
#                 ["ArmsEmbargo", "AssetFreeze", "CharteringOfShips", "ClosureOfRepresentativeOffices",
#                  "CrewServicingOfShipsAndAircraft", "Deflag", "PreventionOfBusinessArrangements",
#                  "PreventionOfCharteringOfShips", "PreventionOfCharteringOfShipsAndAircraft",
#                  "ProhibitionOfPortEntry", "TargetedArmsEmbargo", "TechnicalAssistanceRelatedToAircraft",
#                  "TravelBan", "TrustServicesSanctions"]))
print(foo(test, "UniqueID"))

