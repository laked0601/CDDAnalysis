# CDDAnalysis
A project that collects data from multiple sources on individuals and companies for customer due dilligence. Stores all data in seperate SQL tables and joins them together with views for consolidated queries.
<h2>📌 Description</h2>
<p>The Consolidated Sanctions List project downloads data from various sources such as the ICIJ website, the UK Sanctions List, and the Interpol Red Notices site for individuals and legal entities. The data is then stored in a series of SQLite tables and queried via views to get a consolidated list of individuals across all three sources. The application is accessed via a web interface on a Flask server that can be started by invoking the "start_flask_server.bat" script.</p>
<h2>⚙️ How it Works</h2>
<ul>
  <li>The latest copy of the UK Individual Sanctions list is downloaded in XML from <a href="https://www.gov.uk/government/publications/the-uk-sanctions-list">https://www.gov.uk/government/publications/the-uk-sanctions-list</a></li>
  <li>Queries are made to the backend API that holds the Interpol Red Notices data at <a href="https://ws-public.interpol.int/notices/v1/red">https://ws-public.interpol.int/notices/v1/red</a></li>
  <li>Finally, the offshore leaks database is collected from <a href="https://offshoreleaks.icij.org/pages/database">https://offshoreleaks.icij.org/pages/database</a></li>
  <li>All three sources are combined into seperate tables in an SQLLite database. A main view called "Individuals" consolidates all of these tables and formats with the following query:</li>
</ul>

```sql
select 
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
from ICIJOfficers off
```

<ul><li>Once this is complete, the flask server can be started which includes a form and api for making queries to this table through a web interface.<br>Start "start_flask_server.bat" and go to http://127.0.0.1:5000 to see for yourself.</li></ul>


https://user-images.githubusercontent.com/90655952/235297552-32edac64-808b-4006-8f78-bfdda693443b.mp4


<h2>📁 Installation</h2>
<h3>Prerequisites</h3>
<ul>
  <li>Install Python and add it to your system path<br><a href='https://www.python.org/downloads/'>https://www.python.org/downloads/</a></li>
  <li>Run 'setup.bat' or 'setup.sh'. This will create the required SQLite Database and populate the tables and views needed to store the data.</li>
  <li>*Optional* Install SQLite studio at <a href='https://sqlitestudio.pl/'>https://sqlitestudio.pl/</a>. This is a graphical interface for SQLite will make reading and understanding the data in the SQLite database much easier.</li>
</ul>
<p>Once complete, run 'main.py' to begin.</p>
