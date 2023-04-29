import re
from file_handling import sql_cnxn
from datetime import datetime
import requests
import json
from time import sleep, time


def get_country_codes():
    nationality_select_re = re.compile('(<select .*?id="nationality".*?><\/select>)', re.DOTALL)
    nationality_value_re = re.compile('option value="(.*?)"', re.DOTALL)
    r = requests.get("https://www.interpol.int/en/How-we-work/Notices/View-Red-Notices")
    select_res = nationality_select_re.search(r.text)
    return nationality_value_re.findall(select_res.group(1))


def build_interpol_json():
    def get_notices():
        nonlocal full_json, ids
        print(str(req_params), end=" ")
        r = s.get(endpoint, params=req_params)
        json_resp = r.json()
        print("TOTAL:", json_resp["total"], end=" ")
        notices = json_resp["_embedded"]["notices"]
        i = 0
        for notice in notices:
            if notice["entity_id"] not in ids:
                i += 1
                full_json["_embedded"]["notices"].append(notice)
                ids.add(notice["entity_id"])
        print("NEW NOTICES:", i)
        return json_resp
    with requests.session() as s:
        req_params = {"page": 1, "resultPerPage": 160}
        endpoint = "https://ws-public.interpol.int/notices/v1/red"
        ids = set()
        full_json = {"_embedded": {"notices": []}}
        for country_code in get_country_codes():
            req_params["nationality"] = country_code
            req_json = get_notices()
            if req_json["total"] > 160:
                dif = 20
                start = 0
                new_start = 0
                print("Exceeded maximum notices of 160, sub-querying by age range")
                while start < 120:
                    new_start = start + dif
                    req_params["ageMin"] = start
                    req_params["ageMax"] = new_start
                    req_json = get_notices()
                    if req_json["total"] > 160:
                        if dif == 0:
                            print("Exceeded total for age range, querying by name characters:")
                            for ordval in range(97, 123):
                                req_params["name"] = chr(ordval)
                                req_json = get_notices()
                            del req_params["name"]
                        else:
                            dif //= 2
                            continue
                    elif len(req_json["_embedded"]["notices"]) < 40:
                        dif += 10
                    if dif == 0:
                        start += 1
                    else:
                        start = new_start
                del req_params["ageMin"], req_params["ageMax"]
        with open("interpol-red-notices.json", 'w', encoding="utf-8") as wf:
            wf.write(json.dumps(full_json, indent=4))
        print(len(full_json["_embedded"]["notices"]), "notices found")


def build_interpol_profiles(notices_json=None, time_limit=60*60):
    if notices_json is None:
        with open("interpol-red-notices.json", 'r', encoding="utf-8") as rf:
            notices_json = json.loads(rf.read())
    with requests.session() as s:
        try:
            stime = time()
            for i, notice in enumerate(notices_json["_embedded"]["notices"]):
                if "profile" in notice:
                    continue
                r = s.get(notice["_links"]["self"]["href"])
                print(i, r.status_code, end=" ")
                if r.status_code != 200:
                    print("Sleeping...", end=" ")
                    sleep(30)
                    r = s.get(notice["_links"]["self"]["href"])
                    print(r.status_code, end=" ")
                print()
                notice["profile"] = r.json()
                if time() - stime > time_limit:
                    print("Exiting due to exceeding time limit of %d seconds." % (time_limit,))
                    break
        except Exception as e:
            print(e)
            pass
    with open("interpol-red-notices.json", 'w', encoding="utf-8") as wf:
        wf.write(json.dumps(notices_json, indent=4))


def add_interpol_profiles_to_db():
    with open("interpol-red-notices.json", 'r', encoding="utf-8") as rf:
        content = json.loads(rf.read())

    with sql_cnxn() as cnxn:
        crsr = cnxn.cursor()
        for notice in content["_embedded"]["notices"]:
            forename = notice["profile"]["forename"]
            try:
                date_of_birth = datetime.strptime(notice["profile"]["date_of_birth"], "%Y/%m/%d")
            except:
                date_of_birth = None
            entity_id = notice["profile"]["entity_id"]
            weight = notice["profile"]["weight"]
            height = notice["profile"]["height"]
            sex_id = notice["profile"]["sex_id"]
            country_of_birth_id = notice["profile"]["country_of_birth_id"]
            name = notice["profile"]["name"]
            distinguishing_marks = notice["profile"]["distinguishing_marks"]
            if notice["profile"]["eyes_colors_id"] is not None:
                eyes_colors_id = ', '.join(notice["profile"]["eyes_colors_id"])
            else:
                eyes_colors_id = None
            if notice["profile"]["hairs_id"] is not None:
                hairs_id = ', '.join(notice["profile"]["hairs_id"])
            else:
                hairs_id = None
            place_of_birth = notice["profile"]["place_of_birth"]
            if "nationalities" in notice["profile"] and notice["profile"]["nationalities"] is not None:
                nationalities = notice["profile"]["nationalities"]
            else:
                nationalities = []
            if notice["profile"]["languages_spoken_ids"] is not None:
                languages_spoken_ids = ', '.join(notice["profile"]["languages_spoken_ids"])
            else:
                languages_spoken_ids = None
            warrants = []
            for warrant in notice["profile"]["arrest_warrants"]:
                warrants.append([entity_id, warrant["issuing_country_id"], warrant["charge"], warrant["charge_translation"]])
            crsr.execute("delete from IRNArrestWarrants where entity_id = ?", (entity_id,))
            crsr.execute("delete from IRNNationalities where entity_id = ?", (entity_id,))
            crsr.execute("insert into IRN (forename, date_of_birth, entity_id, name, weight, height, sex_id, "
                         "country_of_birth_id, distinguishing_marks, eyes_colors_id, hairs_id, "
                         "place_of_birth, languages_spoken_ids) "
                         "values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) on conflict (entity_id) do update set "
                         "forename=excluded.forename, date_of_birth=excluded.date_of_birth, "
                         "name=excluded.name, weight=excluded.weight, height=excluded.height, sex_id=excluded.sex_id, "
                         "country_of_birth_id=excluded.country_of_birth_id, "
                         "distinguishing_marks=excluded.distinguishing_marks, eyes_colors_id=excluded.eyes_colors_id, "
                         "hairs_id=excluded.hairs_id, place_of_birth=excluded.place_of_birth, "
                         "languages_spoken_ids=excluded.languages_spoken_ids",
                         (forename, date_of_birth, entity_id, name, weight, height, sex_id, country_of_birth_id,
                          distinguishing_marks, eyes_colors_id, hairs_id, place_of_birth, languages_spoken_ids))
            crsr.executemany("insert into IRNArrestWarrants (entity_id, issuing_country_id, charge, "
                             "charge_translation) values (?, ?, ?, ?)", warrants)
            crsr.executemany("insert into IRNNationalities (entity_id, code) values (?, ?)",
                             [[entity_id, code] for code in nationalities])
        cnxn.commit()


def get_data():
    build_interpol_json()
    build_interpol_profiles()
    add_interpol_profiles_to_db()
