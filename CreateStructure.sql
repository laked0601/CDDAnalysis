--
-- File generated with SQLiteStudio v3.3.3 on Sat Apr 29 05:08:33 2023
--
-- Text encoding used: System
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table: Content Types
CREATE TABLE "Content Types" (PK INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT, "File Extension" TEXT);

-- Table: CountryCodes
CREATE TABLE CountryCodes (PK INTEGER PRIMARY KEY AUTOINCREMENT, Country TEXT, "Alpha-2 code" TEXT, "Alpha-3 code" TEXT, Numeric TEXT);

-- Table: ICIJAddresses
CREATE TABLE ICIJAddresses (node_id INTEGER PRIMARY KEY UNIQUE, address TEXT, name TEXT, countries TEXT, country_codes TEXT, sourceID TEXT, valid_until TEXT, note TEXT);

-- Table: ICIJEntities
CREATE TABLE ICIJEntities (node_id INTEGER UNIQUE PRIMARY KEY, name TEXT, original_name TEXT, former_name TEXT, jurisdiction TEXT, jurisdiction_description TEXT, company_type TEXT, address TEXT, internal_id INTEGER, incorporation_date DATETIME, inactivation_date DATETIME, struck_off_date DATETIME, dorm_date DATETIME, status TEXT, service_provider TEXT, ibcRUC TEXT, country_codes TEXT, countries TEXT, sourceID TEXT, valid_until TEXT, note TEXT);

-- Table: ICIJIntermediaries
CREATE TABLE ICIJIntermediaries (node_id INTEGER PRIMARY KEY UNIQUE, name TEXT, status TEXT, internal_id INTEGER, address TEXT, countries TEXT, country_codes TEXT, sourceID TEXT, valid_until TEXT, note TEXT);

-- Table: ICIJOfficers
CREATE TABLE ICIJOfficers (node_id INTEGER PRIMARY KEY UNIQUE, name TEXT, countries TEXT, country_codes TEXT, sourceID TEXT, valid_until TEXT, note TEXT);

-- Table: ICIJOthers
CREATE TABLE ICIJOthers (node_id INTEGER PRIMARY KEY UNIQUE, name TEXT, type TEXT, incorporation_date DATETIME, struck_off_date DATETIME, closed_date DATETIME, jurisdiction TEXT, jurisdiction_description TEXT, countries TEXT, country_codes TEXT, sourceID TEXT, valid_until TEXT, note TEXT);

-- Table: ICIJRelationships
CREATE TABLE ICIJRelationships (node_id_start INTEGER, node_id_end INTEGER, rel_type TEXT, link TEXT, start_date DATETIME, end_date DATETIME, sourceID TEXT);

-- Table: Images
CREATE TABLE Images (PK INTEGER PRIMARY KEY AUTOINCREMENT, DataSourceName TEXT, DataSourceID TEXT, ImageLocation TEXT, SourceURL TEXT, ContentType INTEGER REFERENCES "Content Types" (PK) ON DELETE RESTRICT ON UPDATE RESTRICT MATCH SIMPLE);

-- Table: IRN
CREATE TABLE IRN (forename TEXT, date_of_birth DATETIME, entity_id TEXT UNIQUE NOT NULL PRIMARY KEY, name TEXT, weight INTEGER, height REAL (3, 2), sex_id TEXT, country_of_birth_id TEXT, distinguishing_marks TEXT, eyes_colors_id TEXT, hairs_id TEXT, place_of_birth TEXT, languages_spoken_ids TEXT);

-- Table: IRNArrestWarrants
CREATE TABLE IRNArrestWarrants (PK INTEGER PRIMARY KEY AUTOINCREMENT, entity_id TEXT REFERENCES IRN (entity_id) ON DELETE CASCADE ON UPDATE CASCADE MATCH SIMPLE NOT NULL, issuing_country_id TEXT, charge TEXT, charge_translation TEXT);

-- Table: IRNNationalities
CREATE TABLE IRNNationalities (PK INTEGER PRIMARY KEY AUTOINCREMENT, entity_id TEXT REFERENCES IRN (entity_id) ON DELETE CASCADE ON UPDATE CASCADE MATCH SIMPLE, code TEXT);

-- Table: UKSanctionsList
CREATE TABLE UKSanctionsList (LastUpdated DATE, DateDesignated DATE, UniqueID TEXT UNIQUE NOT NULL PRIMARY KEY, OFSIGroupID INTEGER, UNReferenceNumber TEXT, RegimeName TEXT, IndividualEntityShip TEXT, DesignationSource TEXT, SanctionsImposed TEXT, OtherInformation TEXT, UKStatementofReasons TEXT, ArmsEmbargo BOOLEAN, AssetFreeze BOOLEAN, CharteringOfShips BOOLEAN, ClosureOfRepresentativeOffices BOOLEAN, CrewServicingOfShipsAndAircraft BOOLEAN, Deflag BOOLEAN, PreventionOfBusinessArrangements BOOLEAN, PreventionOfCharteringOfShips BOOLEAN, PreventionOfCharteringOfShipsAndAircraft BOOLEAN, ProhibitionOfPortEntry BOOLEAN, TargetedArmsEmbargo BOOLEAN, TechnicalAssistanceRelatedToAircraft BOOLEAN, TravelBan BOOLEAN, TrustServicesSanctions BOOLEAN);

-- Table: UKSanctionsListAddresses
CREATE TABLE UKSanctionsListAddresses (PK INTEGER PRIMARY KEY AUTOINCREMENT, UniqueID TEXT NOT NULL REFERENCES UKSanctionsList (UniqueID) ON DELETE CASCADE ON UPDATE CASCADE MATCH SIMPLE, AddressLine1 TEXT, AddressLine2 TEXT, AddressLine3 TEXT, AddressLine4 TEXT, AddressLine5 TEXT, AddressLine6 TEXT, AddressPostalCode TEXT, AddressCountry TEXT);

-- Table: UKSanctionsListBirthDetails
CREATE TABLE UKSanctionsListBirthDetails (PK INTEGER PRIMARY KEY AUTOINCREMENT, UniqueID TEXT REFERENCES UKSanctionsList (UniqueID) ON DELETE CASCADE ON UPDATE CASCADE MATCH SIMPLE, TownOfBirth TEXT, CountryOfBirth TEXT);

-- Table: UKSanctionsListDOBs
CREATE TABLE UKSanctionsListDOBs (PK INTEGER PRIMARY KEY AUTOINCREMENT, UniqueID TEXT REFERENCES UKSanctionsList (UniqueID) ON DELETE CASCADE ON UPDATE CASCADE MATCH SIMPLE, DOB DATETIME);

-- Table: UKSanctionsListGenders
CREATE TABLE UKSanctionsListGenders (PK INTEGER PRIMARY KEY AUTOINCREMENT, UniqueID TEXT REFERENCES UKSanctionsList (UniqueID) ON DELETE CASCADE ON UPDATE CASCADE MATCH SIMPLE, Gender TEXT);

-- Table: UKSanctionsListNames
CREATE TABLE UKSanctionsListNames (PK INTEGER PRIMARY KEY AUTOINCREMENT, UniqueID TEXT REFERENCES UKSanctionsList (UniqueID) ON DELETE CASCADE ON UPDATE CASCADE MATCH SIMPLE NOT NULL, Name1 TEXT, Name2 TEXT, Name3 TEXT, Name4 TEXT, Name5 TEXT, Name6 TEXT, NameType TEXT, AliasStrength TEXT);

-- Table: UKSanctionsListNationalities
CREATE TABLE UKSanctionsListNationalities (PK INTEGER PRIMARY KEY AUTOINCREMENT, UniqueID TEXT REFERENCES UKSanctionsList (UniqueID) ON DELETE CASCADE ON UPDATE CASCADE MATCH SIMPLE, Nationality TEXT);

-- Table: UKSanctionsListPassportDetails
CREATE TABLE UKSanctionsListPassportDetails (PK INTEGER PRIMARY KEY AUTOINCREMENT, UniqueID TEXT REFERENCES UKSanctionsList (UniqueID) ON DELETE CASCADE ON UPDATE CASCADE MATCH SIMPLE, PassportNumber TEXT, PassportAdditionalInformation TEXT);

-- Table: UKSanctionsListPositions
CREATE TABLE UKSanctionsListPositions (PK INTEGER PRIMARY KEY AUTOINCREMENT, UniqueID TEXT REFERENCES UKSanctionsList (UniqueID) ON DELETE CASCADE ON UPDATE CASCADE MATCH SIMPLE, Position TEXT);

-- View: Individuals
CREATE VIEW Individuals AS select 
    'UKSanctionsList' as DataSource,
    ui.UniqueID as DataSourceID,
    trim(replace(replace(replace(lower(
        coalesce(ui.Name1, '') || ' ' || coalesce(ui.Name2, '') || ' ' || 
        coalesce(ui.Name3, '') || ' ' || coalesce(ui.Name4, '') || ' ' || 
        coalesce(ui.Name5, '') || ' ' || coalesce(ui.Name6, '')
    ),' ','<>'),'><',''),'<>',' ')) as FullName,
    ui.NameType as NameType,
    ui.SanctionsImposed as Sanctions,
    ui.OtherInformation as Notes,
    case
        when ui.Gender is null then 'Unknown'
        when ui.Gender not in ('Male', 'Female') then 'Other'
        else ui.Gender
    end as Gender,
    ui.Nationality as Nationality,
    ui.DOB as DOB
from UKSanctionsListIndividuals ui
union
select
    'InterpolRedNotices' as DataSource,
    irn.entity_id as DataSourceID,
    lower(irn.forename) || ' ' || lower(irn.name) as FullName,
    null as NameType,
    null as Sanctions,
    arr.charge as Notes,
    case
        when irn.sex_id is null then 'Unknown'
        when irn.sex_id == 'M' then 'Male'
        when irn.sex_id == 'F' then 'Female'
        else 'Other'
    end as Gender,
    country.Country as Nationality,
    irn.date_of_birth as DOB
from IRN irn
left join IRNArrestWarrants arr on irn.entity_id = arr.entity_id
left join IRNNationalities nat on irn.entity_id = nat.entity_id
left join CountryCodes country on nat.code = country.`Alpha-2 code`
union
select 
    'ICIJOfficers' as DataSource,
    off.node_id as DataSourceID,
    lower(off.name) as FullName,
    null as NameType,
    null as Sanctions,
    'Source: "' || off.sourceID || '" Valid Until: "' || off.valid_until || '"' as Notes,
    'Unknown' as Gender,
    null as Nationality,
    null as DOB
from ICIJOfficers off;

-- View: IRNIndividuals
CREATE VIEW IRNIndividuals AS select nt.*, arr.issuing_country_id, arr.charge, arr.charge_translation from `IRN` nt
left join `IRNArrestWarrants` arr on nt.PK = arr.`Notice PK`;

-- View: UKSanctionsListIndividuals
CREATE VIEW UKSanctionsListIndividuals AS select 
    nm.UniqueID, nm.Name1, nm.Name2, nm.Name3, nm.Name4, nm.Name5, nm.Name6, nm.NameType, 
    nm.AliasStrength, sl.LastUpdated, sl.DateDesignated, sl.OFSIGroupID, sl.UNReferenceNumber, 
    sl.RegimeName, sl.IndividualEntityShip, sl.DesignationSource, sl.SanctionsImposed, 
    sl.OtherInformation, sl.UKStatementofReasons, sl.ArmsEmbargo, sl.AssetFreeze, 
    sl.CharteringOfShips, sl.ClosureOfRepresentativeOffices, sl.CrewServicingOfShipsAndAircraft, 
    sl.Deflag, sl.PreventionOfBusinessArrangements, sl.PreventionOfCharteringOfShips, 
    sl.PreventionOfCharteringOfShipsAndAircraft, sl.ProhibitionOfPortEntry, sl.TargetedArmsEmbargo, 
    sl.TechnicalAssistanceRelatedToAircraft, sl.TravelBan, sl.TrustServicesSanctions, 
    dobs.DOB, nats.Nationality, bd.TownOfBirth, bd.CountryOfBirth, pd.PassportNumber, 
    pd.PassportAdditionalInformation, pos.Position, gen.Gender
from UKSanctionsListNames nm
left join UKSanctionsList sl on nm.UniqueID = sl.UniqueID
left join UKSanctionsListDOBs dobs on nm.UniqueID = dobs.UniqueId
left join UKSanctionsListNationalities nats on nm.UniqueID = nats.UniqueID
left join UKSanctionsListBirthDetails bd on nm.UniqueID = bd.UniqueID
left join UKSanctionsListPassportDetails pd on nm.UniqueID = pd.UniqueID
left join UKSanctionsListPositions pos on nm.UniqueID = pos.UniqueID
left join UKSanctionsListGenders gen on nm.UniqueID = gen.UniqueID
where IndividualEntityShip = 'Individual';

-- View: UKSanctionsView
CREATE VIEW UKSanctionsView AS SELECT res.*, (Name1 || ' ' || Name2 || ' ' || Name3 || ' ' || Name4 || ' ' || Name5 || ' ' || Name6) AS "Full Name" FROM (SELECT usl.*, coalesce(usn.Name1, '') AS Name1, coalesce(usn.Name2, '') AS Name2, coalesce(usn.Name3, '') AS Name3, coalesce(usn.Name4, '') AS Name4, coalesce(usn.Name5, '') AS Name5, coalesce(usn.Name6, '') AS Name6, coalesce(usn.NameType, '') AS NameType, coalesce(usn.AliasStrength, '') AS AliasStrength, coalesce(usa.AddressLine1, '') AS AddressLine1, coalesce(usa.AddressLine2, '') AS AddressLine2, coalesce(usa.AddressLine3, '') AS AddressLine3, coalesce(usa.AddressLine4, '') AS AddressLine4, coalesce(usa.AddressLine5, '') AS AddressLine5, coalesce(usa.AddressLine6, '') AS AddressLine6, coalesce(usa.AddressPostalCode, '') AS AddressPostalCode, coalesce(usa.AddressCountry, '') AS AddressCountry FROM UKSanctionsList usl LEFT JOIN UKSanctionsListNames usn ON usl.PK = usn.UniqueID LEFT JOIN UKSanctionsListAddresses usa ON usl.PK = usa.UniqueID) res;

COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
--
-- File generated with SQLiteStudio v3.3.3 on Sat Apr 29 05:09:29 2023
--
-- Text encoding used: System
--
PRAGMA foreign_keys = off;
BEGIN TRANSACTION;

-- Table: Content Types
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (1, 'application/x-7z-compressed', '.7z');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (2, 'audio/aac', '.aac');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (3, 'application/x-abiword', '.abw');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (4, 'application/x-freearc', '.arc');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (5, 'image/avif', '.avif');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (6, 'video/x-msvideo', '.avi');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (7, 'application/vnd.amazon.ebook', '.azw');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (8, 'application/octet-stream', '.bin');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (9, 'image/bmp', '.bmp');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (10, 'application/x-bzip', '.bz');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (11, 'application/x-bzip2', '.bz2');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (12, 'application/x-cdf', '.cda');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (13, 'application/x-csh', '.csh');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (14, 'text/css', '.css');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (15, 'text/csv', '.csv');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (16, 'application/msword', '.doc');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (17, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', '.docx');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (18, 'application/vnd.ms-fontobject', '.eot');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (19, 'application/epub+zip', '.epub');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (20, 'application/gzip', '.gz');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (21, 'image/gif', '.gif');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (22, 'text/html', '.html');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (23, 'image/vnd.microsoft.icon', '.ico');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (24, 'text/calendar', '.ics');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (25, 'application/java-archive', '.jar');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (26, 'image/jpeg', '.jpg');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (27, 'text/javascript', '.mjs');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (28, 'application/json', '.json');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (29, 'application/ld+json', '.jsonld');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (30, 'audio / midi', '.midi');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (31, 'audio/mpeg', '.mp3');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (32, 'video/mp4', '.mp4');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (33, 'video/mpeg', '.mpeg');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (34, 'application/vnd.apple.installer+xml', '.mpkg');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (35, 'application/vnd.oasis.opendocument.presentation', '.odp');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (36, 'application/vnd.oasis.opendocument.spreadsheet', '.ods');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (37, 'application/vnd.oasis.opendocument.text', '.odt');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (38, 'audio/ogg', '.oga');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (39, 'video/ogg', '.ogv');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (40, 'application/ogg', '.ogx');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (41, 'audio/opus', '.opus');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (42, 'font/otf', '.otf');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (43, 'image/png', '.png');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (44, 'application/pdf', '.pdf');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (45, 'application/x-httpd-php', '.php');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (46, 'application/vnd.ms-powerpoint', '.ppt');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (47, 'application/vnd.openxmlformats-officedocument.presentationml.presentation', '.pptx');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (48, 'application/vnd.rar', '.rar');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (49, 'application/rtf', '.rtf');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (50, 'application/x-sh', '.sh');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (51, 'image/svg+xml', '.svg');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (52, 'application/x-tar', '.tar');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (53, 'image / tiff', '.tif');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (54, 'video/mp2t', '.ts');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (55, 'font/ttf', '.ttf');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (56, 'text/plain', '.txt');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (57, 'application/vnd.visio', '.vsd');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (58, 'audio/wav', '.wav');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (59, 'audio/webm', '.weba');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (60, 'video/webm', '.webm');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (61, 'image/webp', '.webp');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (62, 'font/woff', '.woff');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (63, 'font/woff2', '.woff2');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (64, 'application/xhtml+xml', '.xhtml');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (65, 'application/vnd.ms-excel', '.xls');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (66, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', '.xlsx');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (67, 'application/xml', '.xml');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (68, 'application/vnd.mozilla.xul+xml', '.xul');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (69, 'application/zip', '.zip');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (70, 'video/3gpp', '.3gp');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (71, 'video/3gpp2', '.3g2');
INSERT INTO "Content Types" (PK, Name, "File Extension") VALUES (72, 'text/xml', '.xml');

-- Table: CountryCodes
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (1, 'Afghanistan', 'AF', 'AFG', '4');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (2, 'Albania', 'AL', 'ALB', '8');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (3, 'Algeria', 'DZ', 'DZA', '12');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (4, 'American Samoa', 'AS', 'ASM', '16');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (5, 'Andorra', 'AD', 'AND', '20');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (6, 'Angola', 'AO', 'AGO', '24');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (7, 'Anguilla', 'AI', 'AIA', '660');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (8, 'Antarctica', 'AQ', 'ATA', '10');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (9, 'Antigua and Barbuda', 'AG', 'ATG', '28');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (10, 'Argentina', 'AR', 'ARG', '32');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (11, 'Armenia', 'AM', 'ARM', '51');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (12, 'Aruba', 'AW', 'ABW', '533');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (13, 'Australia', 'AU', 'AUS', '36');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (14, 'Austria', 'AT', 'AUT', '40');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (15, 'Azerbaijan', 'AZ', 'AZE', '31');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (16, 'Bahamas (the)', 'BS', 'BHS', '44');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (17, 'Bahrain', 'BH', 'BHR', '48');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (18, 'Bangladesh', 'BD', 'BGD', '50');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (19, 'Barbados', 'BB', 'BRB', '52');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (20, 'Belarus', 'BY', 'BLR', '112');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (21, 'Belgium', 'BE', 'BEL', '56');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (22, 'Belize', 'BZ', 'BLZ', '84');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (23, 'Benin', 'BJ', 'BEN', '204');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (24, 'Bermuda', 'BM', 'BMU', '60');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (25, 'Bhutan', 'BT', 'BTN', '64');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (26, 'Bolivia (Plurinational State of)', 'BO', 'BOL', '68');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (27, 'Bonaire, Sint Eustatius and Saba', 'BQ', 'BES', '535');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (28, 'Bosnia and Herzegovina', 'BA', 'BIH', '70');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (29, 'Botswana', 'BW', 'BWA', '72');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (30, 'Bouvet Island', 'BV', 'BVT', '74');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (31, 'Brazil', 'BR', 'BRA', '76');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (32, 'British Indian Ocean Territory (the)', 'IO', 'IOT', '86');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (33, 'Brunei Darussalam', 'BN', 'BRN', '96');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (34, 'Bulgaria', 'BG', 'BGR', '100');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (35, 'Burkina Faso', 'BF', 'BFA', '854');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (36, 'Burundi', 'BI', 'BDI', '108');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (37, 'Cabo Verde', 'CV', 'CPV', '132');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (38, 'Cambodia', 'KH', 'KHM', '116');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (39, 'Cameroon', 'CM', 'CMR', '120');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (40, 'Canada', 'CA', 'CAN', '124');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (41, 'Cayman Islands (the)', 'KY', 'CYM', '136');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (42, 'Central African Republic (the)', 'CF', 'CAF', '140');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (43, 'Chad', 'TD', 'TCD', '148');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (44, 'Chile', 'CL', 'CHL', '152');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (45, 'China', 'CN', 'CHN', '156');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (46, 'Christmas Island', 'CX', 'CXR', '162');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (47, 'Cocos (Keeling) Islands (the)', 'CC', 'CCK', '166');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (48, 'Colombia', 'CO', 'COL', '170');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (49, 'Comoros (the)', 'KM', 'COM', '174');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (50, 'Congo (the Democratic Republic of the)', 'CD', 'COD', '180');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (51, 'Congo (the)', 'CG', 'COG', '178');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (52, 'Cook Islands (the)', 'CK', 'COK', '184');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (53, 'Costa Rica', 'CR', 'CRI', '188');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (54, 'Croatia', 'HR', 'HRV', '191');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (55, 'Cuba', 'CU', 'CUB', '192');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (56, 'Curaçao', 'CW', 'CUW', '531');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (57, 'Cyprus', 'CY', 'CYP', '196');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (58, 'Czechia', 'CZ', 'CZE', '203');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (59, 'Côte d''Ivoire', 'CI', 'CIV', '384');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (60, 'Denmark', 'DK', 'DNK', '208');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (61, 'Djibouti', 'DJ', 'DJI', '262');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (62, 'Dominica', 'DM', 'DMA', '212');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (63, 'Dominican Republic (the)', 'DO', 'DOM', '214');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (64, 'Ecuador', 'EC', 'ECU', '218');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (65, 'Egypt', 'EG', 'EGY', '818');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (66, 'El Salvador', 'SV', 'SLV', '222');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (67, 'Equatorial Guinea', 'GQ', 'GNQ', '226');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (68, 'Eritrea', 'ER', 'ERI', '232');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (69, 'Estonia', 'EE', 'EST', '233');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (70, 'Eswatini', 'SZ', 'SWZ', '748');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (71, 'Ethiopia', 'ET', 'ETH', '231');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (72, 'Falkland Islands (the) [Malvinas]', 'FK', 'FLK', '238');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (73, 'Faroe Islands (the)', 'FO', 'FRO', '234');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (74, 'Fiji', 'FJ', 'FJI', '242');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (75, 'Finland', 'FI', 'FIN', '246');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (76, 'France', 'FR', 'FRA', '250');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (77, 'French Guiana', 'GF', 'GUF', '254');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (78, 'French Polynesia', 'PF', 'PYF', '258');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (79, 'French Southern Territories (the)', 'TF', 'ATF', '260');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (80, 'Gabon', 'GA', 'GAB', '266');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (81, 'Gambia (the)', 'GM', 'GMB', '270');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (82, 'Georgia', 'GE', 'GEO', '268');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (83, 'Germany', 'DE', 'DEU', '276');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (84, 'Ghana', 'GH', 'GHA', '288');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (85, 'Gibraltar', 'GI', 'GIB', '292');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (86, 'Greece', 'GR', 'GRC', '300');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (87, 'Greenland', 'GL', 'GRL', '304');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (88, 'Grenada', 'GD', 'GRD', '308');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (89, 'Guadeloupe', 'GP', 'GLP', '312');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (90, 'Guam', 'GU', 'GUM', '316');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (91, 'Guatemala', 'GT', 'GTM', '320');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (92, 'Guernsey', 'GG', 'GGY', '831');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (93, 'Guinea', 'GN', 'GIN', '324');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (94, 'Guinea-Bissau', 'GW', 'GNB', '624');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (95, 'Guyana', 'GY', 'GUY', '328');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (96, 'Haiti', 'HT', 'HTI', '332');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (97, 'Heard Island and McDonald Islands', 'HM', 'HMD', '334');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (98, 'Holy See (the)', 'VA', 'VAT', '336');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (99, 'Honduras', 'HN', 'HND', '340');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (100, 'Hong Kong', 'HK', 'HKG', '344');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (101, 'Hungary', 'HU', 'HUN', '348');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (102, 'Iceland', 'IS', 'ISL', '352');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (103, 'India', 'IN', 'IND', '356');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (104, 'Indonesia', 'ID', 'IDN', '360');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (105, 'Iran (Islamic Republic of)', 'IR', 'IRN', '364');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (106, 'Iraq', 'IQ', 'IRQ', '368');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (107, 'Ireland', 'IE', 'IRL', '372');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (108, 'Isle of Man', 'IM', 'IMN', '833');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (109, 'Israel', 'IL', 'ISR', '376');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (110, 'Italy', 'IT', 'ITA', '380');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (111, 'Jamaica', 'JM', 'JAM', '388');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (112, 'Japan', 'JP', 'JPN', '392');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (113, 'Jersey', 'JE', 'JEY', '832');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (114, 'Jordan', 'JO', 'JOR', '400');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (115, 'Kazakhstan', 'KZ', 'KAZ', '398');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (116, 'Kenya', 'KE', 'KEN', '404');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (117, 'Kiribati', 'KI', 'KIR', '296');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (118, 'Korea (the Democratic People''s Republic of)', 'KP', 'PRK', '408');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (119, 'Korea (the Republic of)', 'KR', 'KOR', '410');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (120, 'Kuwait', 'KW', 'KWT', '414');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (121, 'Kyrgyzstan', 'KG', 'KGZ', '417');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (122, 'Lao People''s Democratic Republic (the)', 'LA', 'LAO', '418');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (123, 'Latvia', 'LV', 'LVA', '428');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (124, 'Lebanon', 'LB', 'LBN', '422');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (125, 'Lesotho', 'LS', 'LSO', '426');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (126, 'Liberia', 'LR', 'LBR', '430');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (127, 'Libya', 'LY', 'LBY', '434');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (128, 'Liechtenstein', 'LI', 'LIE', '438');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (129, 'Lithuania', 'LT', 'LTU', '440');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (130, 'Luxembourg', 'LU', 'LUX', '442');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (131, 'Macao', 'MO', 'MAC', '446');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (132, 'Madagascar', 'MG', 'MDG', '450');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (133, 'Malawi', 'MW', 'MWI', '454');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (134, 'Malaysia', 'MY', 'MYS', '458');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (135, 'Maldives', 'MV', 'MDV', '462');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (136, 'Mali', 'ML', 'MLI', '466');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (137, 'Malta', 'MT', 'MLT', '470');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (138, 'Marshall Islands (the)', 'MH', 'MHL', '584');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (139, 'Martinique', 'MQ', 'MTQ', '474');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (140, 'Mauritania', 'MR', 'MRT', '478');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (141, 'Mauritius', 'MU', 'MUS', '480');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (142, 'Mayotte', 'YT', 'MYT', '175');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (143, 'Mexico', 'MX', 'MEX', '484');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (144, 'Micronesia (Federated States of)', 'FM', 'FSM', '583');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (145, 'Moldova (the Republic of)', 'MD', 'MDA', '498');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (146, 'Monaco', 'MC', 'MCO', '492');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (147, 'Mongolia', 'MN', 'MNG', '496');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (148, 'Montenegro', 'ME', 'MNE', '499');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (149, 'Montserrat', 'MS', 'MSR', '500');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (150, 'Morocco', 'MA', 'MAR', '504');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (151, 'Mozambique', 'MZ', 'MOZ', '508');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (152, 'Myanmar', 'MM', 'MMR', '104');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (153, 'Namibia', 'NA', 'NAM', '516');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (154, 'Nauru', 'NR', 'NRU', '520');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (155, 'Nepal', 'NP', 'NPL', '524');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (156, 'Netherlands (the)', 'NL', 'NLD', '528');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (157, 'New Caledonia', 'NC', 'NCL', '540');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (158, 'New Zealand', 'NZ', 'NZL', '554');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (159, 'Nicaragua', 'NI', 'NIC', '558');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (160, 'Niger (the)', 'NE', 'NER', '562');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (161, 'Nigeria', 'NG', 'NGA', '566');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (162, 'Niue', 'NU', 'NIU', '570');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (163, 'Norfolk Island', 'NF', 'NFK', '574');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (164, 'Northern Mariana Islands (the)', 'MP', 'MNP', '580');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (165, 'Norway', 'NO', 'NOR', '578');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (166, 'Oman', 'OM', 'OMN', '512');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (167, 'Pakistan', 'PK', 'PAK', '586');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (168, 'Palau', 'PW', 'PLW', '585');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (169, 'Palestine, State of', 'PS', 'PSE', '275');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (170, 'Panama', 'PA', 'PAN', '591');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (171, 'Papua New Guinea', 'PG', 'PNG', '598');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (172, 'Paraguay', 'PY', 'PRY', '600');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (173, 'Peru', 'PE', 'PER', '604');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (174, 'Philippines (the)', 'PH', 'PHL', '608');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (175, 'Pitcairn', 'PN', 'PCN', '612');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (176, 'Poland', 'PL', 'POL', '616');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (177, 'Portugal', 'PT', 'PRT', '620');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (178, 'Puerto Rico', 'PR', 'PRI', '630');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (179, 'Qatar', 'QA', 'QAT', '634');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (180, 'Republic of North Macedonia', 'MK', 'MKD', '807');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (181, 'Romania', 'RO', 'ROU', '642');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (182, 'Russian Federation (the)', 'RU', 'RUS', '643');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (183, 'Rwanda', 'RW', 'RWA', '646');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (184, 'Réunion', 'RE', 'REU', '638');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (185, 'Saint Barthélemy', 'BL', 'BLM', '652');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (186, 'Saint Helena, Ascension and Tristan da Cunha', 'SH', 'SHN', '654');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (187, 'Saint Kitts and Nevis', 'KN', 'KNA', '659');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (188, 'Saint Lucia', 'LC', 'LCA', '662');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (189, 'Saint Martin (French part)', 'MF', 'MAF', '663');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (190, 'Saint Pierre and Miquelon', 'PM', 'SPM', '666');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (191, 'Saint Vincent and the Grenadines', 'VC', 'VCT', '670');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (192, 'Samoa', 'WS', 'WSM', '882');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (193, 'San Marino', 'SM', 'SMR', '674');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (194, 'Sao Tome and Principe', 'ST', 'STP', '678');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (195, 'Saudi Arabia', 'SA', 'SAU', '682');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (196, 'Senegal', 'SN', 'SEN', '686');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (197, 'Serbia', 'RS', 'SRB', '688');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (198, 'Seychelles', 'SC', 'SYC', '690');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (199, 'Sierra Leone', 'SL', 'SLE', '694');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (200, 'Singapore', 'SG', 'SGP', '702');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (201, 'Sint Maarten (Dutch part)', 'SX', 'SXM', '534');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (202, 'Slovakia', 'SK', 'SVK', '703');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (203, 'Slovenia', 'SI', 'SVN', '705');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (204, 'Solomon Islands', 'SB', 'SLB', '90');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (205, 'Somalia', 'SO', 'SOM', '706');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (206, 'South Africa', 'ZA', 'ZAF', '710');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (207, 'South Georgia and the South Sandwich Islands', 'GS', 'SGS', '239');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (208, 'South Sudan', 'SS', 'SSD', '728');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (209, 'Spain', 'ES', 'ESP', '724');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (210, 'Sri Lanka', 'LK', 'LKA', '144');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (211, 'Sudan (the)', 'SD', 'SDN', '729');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (212, 'Suriname', 'SR', 'SUR', '740');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (213, 'Svalbard and Jan Mayen', 'SJ', 'SJM', '744');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (214, 'Sweden', 'SE', 'SWE', '752');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (215, 'Switzerland', 'CH', 'CHE', '756');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (216, 'Syrian Arab Republic', 'SY', 'SYR', '760');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (217, 'Taiwan (Province of China)', 'TW', 'TWN', '158');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (218, 'Tajikistan', 'TJ', 'TJK', '762');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (219, 'Tanzania, United Republic of', 'TZ', 'TZA', '834');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (220, 'Thailand', 'TH', 'THA', '764');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (221, 'Timor-Leste', 'TL', 'TLS', '626');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (222, 'Togo', 'TG', 'TGO', '768');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (223, 'Tokelau', 'TK', 'TKL', '772');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (224, 'Tonga', 'TO', 'TON', '776');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (225, 'Trinidad and Tobago', 'TT', 'TTO', '780');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (226, 'Tunisia', 'TN', 'TUN', '788');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (227, 'Turkey', 'TR', 'TUR', '792');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (228, 'Turkmenistan', 'TM', 'TKM', '795');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (229, 'Turks and Caicos Islands (the)', 'TC', 'TCA', '796');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (230, 'Tuvalu', 'TV', 'TUV', '798');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (231, 'Uganda', 'UG', 'UGA', '800');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (232, 'Ukraine', 'UA', 'UKR', '804');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (233, 'United Arab Emirates (the)', 'AE', 'ARE', '784');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (234, 'United Kingdom of Great Britain and Northern Ireland (the)', 'GB', 'GBR', '826');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (235, 'United States Minor Outlying Islands (the)', 'UM', 'UMI', '581');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (236, 'United States of America (the)', 'US', 'USA', '840');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (237, 'Uruguay', 'UY', 'URY', '858');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (238, 'Uzbekistan', 'UZ', 'UZB', '860');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (239, 'Vanuatu', 'VU', 'VUT', '548');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (240, 'Venezuela (Bolivarian Republic of)', 'VE', 'VEN', '862');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (241, 'Viet Nam', 'VN', 'VNM', '704');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (242, 'Virgin Islands (British)', 'VG', 'VGB', '92');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (243, 'Virgin Islands (U.S.)', 'VI', 'VIR', '850');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (244, 'Wallis and Futuna', 'WF', 'WLF', '876');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (245, 'Western Sahara', 'EH', 'ESH', '732');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (246, 'Yemen', 'YE', 'YEM', '887');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (247, 'Zambia', 'ZM', 'ZMB', '894');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (248, 'Zimbabwe', 'ZW', 'ZWE', '716');
INSERT INTO CountryCodes (PK, Country, "Alpha-2 code", "Alpha-3 code", Numeric) VALUES (249, 'Åland Islands', 'AX', 'ALA', '248');

COMMIT TRANSACTION;
PRAGMA foreign_keys = on;
