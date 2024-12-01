from playwright.sync_api import Page, expect


# def test_saif_title(page: Page):
#     page.goto("https://www.saif.com/aboutsaif.html")
#
#     # Expect a title "to contain" a substring.
#     expect(page).to_have_title("About SAIF | Oregon's Workers' Compensation Insurance Leader")


def test_tent_price(page: Page):
    page.goto("https://www.backcountry.com/marmot-superalloy-tent-2-person-3-season")

    expect(page.get_by_text("45% off")).to_be_visible()
