import requests
import os
from file_handling import get_content_type, sql_cnxn


# !! IN DEVELOPMENT !!
# for collecting images of individuals in the database via google search
#
#


# Define the API key and the search engine ID
API_KEY = "{{APIKEY}}"
SEARCH_ENGINE_ID = "{{SEARCH_ENGINE_ID}}"
URL = "https://www.googleapis.com/customsearch/v1"


def get_images(data_source, data_source_id, search_phrase, replace_existing_images=False, max_images=10):
    new_dirpath = "Collected Images/%s-%s" % (data_source, data_source_id)
    if not os.path.exists(new_dirpath):
        os.mkdir(new_dirpath)
    with os.scandir(new_dirpath) as direntry:
        for file in direntry:
            if replace_existing_images == False:
                return
            break
    with sql_cnxn() as cnxn:
        crsr = cnxn.cursor()
        response = requests.get(
            URL,
            params={"key": API_KEY, "cx": SEARCH_ENGINE_ID, "searchType": "image", "q": search_phrase}
        )
        if response.status_code == 429:
            raise Exception("Unable to proceed as too many requests made to google API!")
        response = response.json()
        image_urls = []
        for item in response.get("items", [])[:max_images]:
            image_urls.append(item.get("link"))
        for i, url in enumerate(image_urls):
            image_path = None
            content_type = None
            try:
                r = requests.get(url, timeout=30)
                if len(r.content) > 0:
                    lowered_headers = {k.lower(): v for k, v in r.headers.items()}
                    content_type = None
                    if "content-type" in lowered_headers:
                        content_type = get_content_type(from_header=lowered_headers["content-type"])
                    if content_type is None:
                        extension = url[url.rfind('.'):]
                        content_type = get_content_type(from_extension=extension)
                    if content_type is None:
                        raise Exception("Unable to determine content type for '%s'!" % (url,))
                    image_path = "%s/%d%s" % (new_dirpath, i, content_type.extension)
                    with open(image_path, 'wb') as wf:
                        wf.write(r.content)
                else:
                    raise Exception("Status code returned %d with file size of %d for url '%s'" %
                                    (r.status_code, len(r.content), url))
            except Exception as e:
                print(e)
                continue
            crsr.execute("insert into Images (DataSourceName, DataSourceID, ImageLocation, SourceURL, ContentType) "
                         "values (?, ?, ?, ?, ?)", (data_source, data_source_id, image_path, url, content_type.pk))
            cnxn.commit()


with sql_cnxn() as cnxn:
    crsr = cnxn.cursor()
    crsr.execute(
        "select res.* from (select DataSourceID, FullName || ' ' || coalesce(Nationality, ''), ROW_NUMBER() OVER ( "
        "    ORDER BY 1 "
        ") as row_number from Individuals where DataSource = 'UKSanctionsList'  "
        "and NameType = 'Primary Name' group by DataSourceID) res "
        "where (res.row_number + 1) % 4 = 0 "
    )
    rows = crsr.fetchall()
for row in rows:
    print(row[1])
    get_images(data_source="UKSanctionsList", data_source_id=row[0], search_phrase=row[1])
