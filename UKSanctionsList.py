import re
import xml.etree.ElementTree as ET
from file_handling import sql_cnxn
import requests
from datetime import datetime


class Designation:
    name_headers = ["Name1", "Name2", "Name3", "Name4", "Name5", "Name6", "NameType", "AliasStrength"]
    name_lookup = {k: i for i, k in enumerate(name_headers)}
    sanctions_headers = ["ArmsEmbargo", "AssetFreeze", "CharteringOfShips", "ClosureOfRepresentativeOffices",
                         "CrewServicingOfShipsAndAircraft", "Deflag", "PreventionOfBusinessArrangements",
                         "PreventionOfCharteringOfShips", "PreventionOfCharteringOfShipsAndAircraft",
                         "ProhibitionOfPortEntry", "TargetedArmsEmbargo", "TechnicalAssistanceRelatedToAircraft",
                         "TravelBan", "TrustServicesSanctions"]
    sanctions_lookup = {k: i for i, k in enumerate(sanctions_headers)}
    address_headers = ["AddressLine1", "AddressLine2", "AddressLine3", "AddressLine4", "AddressLine5", "AddressLine6",
                       "AddressPostalCode", "AddressCountry"]
    address_lookup = {k: i for i, k in enumerate(address_headers)}
    other_attribute_headers = ["LastUpdated", "DateDesignated", "UniqueID", "OFSIGroupID",
                               "UNReferenceNumber", "RegimeName", "IndividualEntityShip", "DesignationSource",
                               "SanctionsImposed", "OtherInformation", "UKStatementofReasons"]
    dob_re = re.compile("^(\w{2})\/(\w{2})\/(\w{4})$")

    def __init__(self, xmlelement):
        self.xml = xmlelement
        self.names = []
        self.sanctions = [None for _ in Designation.sanctions_headers]
        self.addresses = []
        self.designation_pk = None
        self.UniqueID = None
        self.IndividualEntityShip = None
        self.DOBs = []
        self.PassportDetails = []
        self.PassportDetails = []
        self.Nationalities = []
        self.Positions = []
        self.BirthDetails = []
        self.Genders = []
        for attr in self.other_attribute_headers:
            res = self.xml.find(attr)
            if res is not None:
                setattr(self, attr, res.text)
            else:
                setattr(self, attr, None)
        self.add_names()
        self.add_addresses()
        self.add_sanctions()
        self.add_individual_details()

    def add_names(self):
        for nm in self.xml.findall("./Names/Name"):
            name_parts = nm.findall("./*")
            name_template = [None for _ in Designation.name_headers]
            for np in name_parts:
                name_template[Designation.name_lookup[np.tag]] = np.text
            self.names.append(name_template)

    def add_addresses(self):
        for adr in self.xml.findall("./Addresses/Address"):
            address_template = [None for _ in Designation.address_headers]
            for i in adr.findall("./*"):
                address_template[Designation.address_lookup[i.tag]] = i.text
            self.addresses.append(address_template)

    def add_sanctions(self):
        for sc in self.xml.findall("./SanctionsImposedIndicators/*"):
            self.sanctions[Designation.sanctions_lookup[sc.tag]] = sc.text

    def add_individual_details(self):
        self.DOBs = []
        for x in self.xml.findall("./IndividualDetails/Individual/DOBs/*"):
            res = Designation.dob_re.search(x.text)
            if res is None:
                if len(x.text) == 4 and x.text.isnumeric():
                    self.DOBs.append(datetime(int(x.text), 1, 1))
                    continue

            day = res.group(1)
            if day.isnumeric():
                day = int(day)
                if day > 31 or day < 1:
                    day = 1
            else:
                day = 1
            month = res.group(2)
            if month.isnumeric():
                month = int(month)
                if month > 12 or month < 1:
                    month = 1
            else:
                month = 1
            self.DOBs.append(datetime(int(res.group(3)), month, day))
        self.PassportDetails = []
        for passport in self.xml.findall("./IndividualDetails/Individual/PassportDetails/*"):
            append_row = [None, None]
            for x in passport.findall("./*"):
                if x.tag == "PassportNumber":
                    append_row[0] = x.text
                elif x.tag == "PassportAdditionalInformation":
                    append_row[1] = x.text
            self.PassportDetails.append(append_row)
        self.Nationalities = [x.text for x in self.xml.findall("./IndividualDetails/Individual/Nationalities/*")]
        self.Positions = [x.text for x in self.xml.findall("./IndividualDetails/Individual/Positions/*")]
        self.Genders = [x.text for x in self.xml.findall("./IndividualDetails/Individual/Genders/*")]
        self.BirthDetails = []
        for Location in self.xml.findall("./IndividualDetails/Individual/BirthDetails/*"):
            append_row = [None, None]
            for x in Location.findall("./*"):
                if x.tag == "TownOfBirth":
                    append_row[0] = x.text
                elif x.tag == "CountryOfBirth":
                    append_row[1] = x.text
            self.BirthDetails.append(append_row)

    def add_to_sql(self, crsr):
        designation_params = (
            [getattr(self, x) for x in Designation.other_attribute_headers] +
            self.sanctions
        )
        crsr.execute("delete from UKSanctionsListNames where UniqueID = ?", (self.UniqueID,))
        crsr.execute("delete from UKSanctionsListAddresses where UniqueID = ?", (self.UniqueID,))
        crsr.execute("delete from UKSanctionsListDOBs where UniqueID = ?", (self.UniqueID,))
        crsr.execute("delete from UKSanctionsListNationalities where UniqueID = ?", (self.UniqueID,))
        crsr.execute("delete from UKSanctionsListPassportDetails where UniqueID = ?", (self.UniqueID,))
        crsr.execute("delete from UKSanctionsListPositions where UniqueID = ?", (self.UniqueID,))
        crsr.execute("delete from UKSanctionsListBirthDetails where UniqueID = ?", (self.UniqueID,))
        crsr.execute("delete from UKSanctionsListGenders where UniqueID = ?", (self.UniqueID,))
        crsr.execute(
            "insert into UKSanctionsList (LastUpdated, DateDesignated, UniqueID, OFSIGroupID, UNReferenceNumber, "
            "RegimeName, IndividualEntityShip, DesignationSource, SanctionsImposed, OtherInformation, "
            "UKStatementofReasons, ArmsEmbargo, AssetFreeze, CharteringOfShips, ClosureOfRepresentativeOffices, "
            "CrewServicingOfShipsAndAircraft, Deflag, PreventionOfBusinessArrangements, PreventionOfCharteringOfShips, "
            "PreventionOfCharteringOfShipsAndAircraft, ProhibitionOfPortEntry, TargetedArmsEmbargo, "
            "TechnicalAssistanceRelatedToAircraft, TravelBan, TrustServicesSanctions) values (?, ?, ?, ?, ?, ?, ?, ?, "
            "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) on conflict (UniqueID) do update set "
            "LastUpdated=excluded.LastUpdated, DateDesignated=excluded.DateDesignated, "
            "OFSIGroupID=excluded.OFSIGroupID, UNReferenceNumber=excluded.UNReferenceNumber, "
            "RegimeName=excluded.RegimeName, IndividualEntityShip=excluded.IndividualEntityShip, "
            "DesignationSource=excluded.DesignationSource, SanctionsImposed=excluded.SanctionsImposed, "
            "OtherInformation=excluded.OtherInformation, UKStatementofReasons=excluded.UKStatementofReasons, "
            "ArmsEmbargo=excluded.ArmsEmbargo, AssetFreeze=excluded.AssetFreeze, "
            "CharteringOfShips=excluded.CharteringOfShips, "
            "ClosureOfRepresentativeOffices=excluded.ClosureOfRepresentativeOffices, "
            "CrewServicingOfShipsAndAircraft=excluded.CrewServicingOfShipsAndAircraft, "
            "Deflag=excluded.Deflag, PreventionOfBusinessArrangements=excluded.PreventionOfBusinessArrangements, "
            "PreventionOfCharteringOfShips=excluded.PreventionOfCharteringOfShips, "
            "PreventionOfCharteringOfShipsAndAircraft=excluded.PreventionOfCharteringOfShipsAndAircraft, "
            "ProhibitionOfPortEntry=excluded.ProhibitionOfPortEntry, TargetedArmsEmbargo=excluded.TargetedArmsEmbargo, "
            "TechnicalAssistanceRelatedToAircraft=excluded.TechnicalAssistanceRelatedToAircraft, "
            "TravelBan=excluded.TravelBan, TrustServicesSanctions=excluded.TrustServicesSanctions",
            designation_params
        )
        crsr.executemany("insert into UKSanctionsListNames (UniqueID, Name1, Name2, Name3, Name4, "
                         "Name5, Name6, NameType, AliasStrength) values (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                         [[self.UniqueID] + x for x in self.names])
        crsr.executemany("insert into UKSanctionsListAddresses (UniqueID, AddressLine1, AddressLine2, "
                         "AddressLine3, AddressLine4, AddressLine5, AddressLine6, AddressPostalCode, AddressCountry) "
                         "values (?, ?, ?, ?, ?, ?, ?, ?, ?)", [[self.UniqueID] + x for x in self.addresses])
        crsr.executemany("insert into UKSanctionsListAddresses (UniqueID, AddressLine1, AddressLine2, "
                         "AddressLine3, AddressLine4, AddressLine5, AddressLine6, AddressPostalCode, AddressCountry) "
                         "values (?, ?, ?, ?, ?, ?, ?, ?, ?)", [[self.UniqueID] + x for x in self.addresses])
        crsr.executemany("insert into UKSanctionsListBirthDetails (UniqueID, TownOfBirth, CountryOfBirth) "
                         "values (?, ?, ?)", [[self.UniqueID] + x for x in self.BirthDetails])
        crsr.executemany("insert into UKSanctionsListDOBs (UniqueID, DOB) "
                         "values (?, ?)", [(self.UniqueID, x) for x in self.DOBs])
        crsr.executemany("insert into UKSanctionsListNationalities (UniqueID, Nationality) "
                         "values (?, ?)", [(self.UniqueID, x) for x in self.Nationalities])
        crsr.executemany("insert into UKSanctionsListPassportDetails (UniqueID, PassportNumber, "
                         "PassportAdditionalInformation) "
                         "values (?, ?, ?)", [[self.UniqueID] + x for x in self.PassportDetails])
        crsr.executemany("insert into UKSanctionsListPositions (UniqueID, Position)"
                         "values (?, ?)", [(self.UniqueID, x) for x in self.Positions])
        crsr.executemany("insert into UKSanctionsListGenders (UniqueID, Gender)"
                         "values (?, ?)", [(self.UniqueID, x) for x in self.Genders])


def add_designations(xml_path):
    tr = ET.parse(xml_path)
    root = tr.getroot()
    with sql_cnxn() as cnxn:
        crsr = cnxn.cursor()
        for x in root.findall("./Designation"):
            r = Designation(x)
            r.add_to_sql(crsr)
        cnxn.commit()


def get_xml():
    r = requests.get("https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/"
                     "file/1152349/UK_Sanctions_List.xml")
    with open("uk-sanctions.xml", 'wb') as wf:
        wf.write(r.content)


def get_data():
    get_xml()
    add_designations("uk-sanctions.xml")

