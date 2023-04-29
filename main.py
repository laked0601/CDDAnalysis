from InterpolRedNotices import get_data as get_interpol_data
from ICIJ import get_data as get_icij_data
from UKSanctionsList import get_data as get_uk_sanctions_data


if __name__ == "__main__":
    # Displays the process for downloading the data from the interpol red notices website at:
    # https://www.interpol.int/en/How-we-work/Notices/View-Red-Notices
    get_interpol_data()

    # Downloads and processes the XML file containing the latest UK Sanctions at
    # https://www.gov.uk/government/publications/the-uk-sanctions-list
    get_uk_sanctions_data()

    # Collects the data from the ICIJ on offshore entities at
    # https://offshoreleaks.icij.org/pages/database
    get_icij_data()
