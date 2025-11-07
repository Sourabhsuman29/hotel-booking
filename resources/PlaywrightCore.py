import json
import os
import re
import datetime
import logging
import subprocess
from dotenv import load_dotenv
from flask.cli import load_dotenv
from robot.api import logger
from playwright.sync_api import sync_playwright, expect
from robot.api.deco import keyword

# ---------------- Logging Setup ----------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("playwright_core.log"),
        logging.StreamHandler()
    ]
)
logger1 = logging.getLogger(__name__)

# # Setup basic logging
logging.basicConfig(level=logging.INFO)

# # Load environment variables from .env file
# env_loaded = load_dotenv()
# logging.info(f".env file loaded: {env_loaded}")
# # Verify that DOPPLER_TOKEN is set
# token = os.getenv("DOPPLER_TOKEN")
# print(token)

# Created Playwright core class python library
class PlaywrightCore:
    browser = None
    context = None
    page = None
    pwSync = None

    # ---------------- Browser ----------------
    #launching Application
    @keyword("Launch Browser Application")
    def launch_browser_application(self, browser_name="chromium"):
        print(f"Launching browser: {browser_name}")
        PlaywrightCore.pwSync = sync_playwright().start()
        if browser_name.lower() == 'chromium':
            PlaywrightCore.browser = PlaywrightCore.pwSync.chromium.launch(headless=False, slow_mo=500)
        elif browser_name.lower() == 'firefox':
            PlaywrightCore.browser = PlaywrightCore.pwSync.firefox.launch(headless=False, slow_mo=500)
        elif browser_name.lower() == 'webkit':
            PlaywrightCore.browser = PlaywrightCore.pwSync.webkit.launch(headless=False, slow_mo=500)
        else:
            logger.error(f"Unsupported browser: {browser_name}")
            raise ValueError(f"Unsupported browser: {browser_name}")

        # Create context with maximized window
        PlaywrightCore.context = PlaywrightCore.browser.new_context(
            viewport=None  # removes default viewport, maximizes browser
        )
        # Create new page
        PlaywrightCore.page = PlaywrightCore.context.new_page()
        PlaywrightCore.page.goto("https://automationintesting.online/")
        print("Browser launched and application opened.")

    #closing browser
    @keyword("Close Browser")
    def close_browser(self):
        if PlaywrightCore.page:
            PlaywrightCore.page.close()
        if PlaywrightCore.context:
            PlaywrightCore.context.close()
        if PlaywrightCore.browser:
            PlaywrightCore.browser.close()
        if PlaywrightCore.pwSync:
            PlaywrightCore.pwSync.stop()
        logger.info("Browser and context closed.")

    #capture screen shot
    @keyword("Capture Screenshot")
    def capture_screenshot(self, name="screenshot"):
        if not PlaywrightCore.page:
            raise RuntimeError("No page is open.")
        folder = "screenshots"
        os.makedirs(folder, exist_ok=True)
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        filepath = os.path.join(folder, f"{name}_{timestamp}.png")
        PlaywrightCore.page.screenshot(path=filepath)
        logger.info(f"Screenshot saved: {filepath}")

    #using doppler to store secrets and fetching using env variable
    @keyword("Get Doppler Secrets")
    def fetch_doppler_secrets(self):
        load_dotenv()
        token = os.getenv("DOPPLER_TOKEN")
        if not token:
            raise ValueError("DOPPLER_TOKEN is not set")

        result = subprocess.run([
            "curl", "-s",
            "-H", f"Authorization: Bearer {token}",
            "https://api.doppler.com/v3/configs/config/secrets/download?format=json"
        ], capture_output=True, text=True)

        if result.returncode != 0 or not result.stdout:
            raise RuntimeError("Failed to fetch secrets from Doppler")

        try:
            secrets = json.loads(result.stdout)
            print(" Doppler secrets fetched:", secrets)
            return secrets
        except json.JSONDecodeError:
            raise ValueError("Invalid JSON response from Doppler")

    # ----------------Below are the application Booking Flow ----------------
    @keyword("Login As Admin")
    def login_as_admin(self):
        page = PlaywrightCore.page

        # importing the module as it required inside the function only
        import os
        import json
        import requests
        from dotenv import load_dotenv
        import logging

        # Setup basic logging
        logging.basicConfig(level=logging.INFO)

        # Load environment variables from .env file
        env_loaded = load_dotenv()
        logging.info(f".env file loaded: {env_loaded}")

        # Verify that DOPPLER_TOKEN is set
        token = os.getenv("DOPPLER_TOKEN")
        print(token)
        if not token:
            raise ValueError("DOPPLER_TOKEN is not set in the .env file")

        # Define the Doppler API URL
        url = "https://api.doppler.com/v3/configs/config/secrets/download?format=json"
        headers = {
            "Authorization": f"Bearer {token}"
        }

        # Make the request using Python's requests library
        response = requests.get(url, headers=headers)

        # Check for successful response
        if response.status_code != 200:
            raise RuntimeError(
                f"Failed to fetch secrets. Status code: {response.status_code}, Response: {response.text}")

        # Parse the JSON response
        try:
            secrets = response.json()
            username = secrets["USER"]
            password = secrets["PASSWORD"]
            logging.info("Secrets fetched successfully:")
            print(json.dumps(secrets, indent=2))
        except json.JSONDecodeError as e:
            raise ValueError(f"Failed to parse JSON response: {e}")

        if not username or not password:
            raise ValueError("Environment variables are not set.")

        try:
            page.get_by_role("link", name="Admin", exact=True).click()
            expect(page.get_by_role("textbox", name="Username")).to_be_visible()

            page.get_by_role("textbox", name="Username").fill(username)
            page.get_by_role("textbox", name="Password").fill(password)
            page.get_by_role("button", name="Login").click(force=True)

            expect(page.locator("#navbarSupportedContent")).to_contain_text("Rooms")
            expect(page.get_by_role("link", name="Front Page")).to_be_visible()
            page.wait_for_timeout(3000)
            # expect(page.locator("// a[normalize - space() = 'Rooms']")).to_be_visible()
            logger.info("Admin login successful.")
        except Exception as e:
            raise RuntimeError(f"Failed to click 'Admin' link: {str(e)}")

    #clicking on frontpage link
    @keyword("Go Back To Front Page")
    def go_back_to_front_page(self):
        page = PlaywrightCore.page
        expect(page.get_by_role("link", name="Front Page")).to_be_visible()
        front_page_link = page.locator("xpath=//a[@id='frontPageLink']")
        front_page_link.wait_for(state="visible", timeout=5000)
        front_page_link.click()

        # Optional: Validate navigation
        assert "automationintesting.online" in page.url and "/admin" not in page.url
        logger.info("clicked on Home/Front Page.")

    #selecting date for booking
    @keyword("Select Dates")
    def select_dates(self, checkin_date=None, checkout_date=None):
        page = PlaywrightCore.page
        # for _ in range(1):
        #     page.keyboard.press("PageDown")
        #     page.wait_for_timeout(500)
        page.locator("div").filter(has_text=re.compile(r"^Check In$")).get_by_role("textbox").click()
        page.get_by_role("button", name="Next Month").click()
        page.get_by_role("option", name="Choose Friday, 14 November").click()
        page.locator("div").filter(has_text=re.compile(r"^Check Out$")).get_by_role("textbox").click()
        page.get_by_role("button", name="Next Month").click()
        page.get_by_role("option", name="Choose Saturday, 15 November").click()
        page.get_by_role("button", name="Check Availability").click()
        logger.info("Clicked on checked availability")

    #select room type from the to proceed booking
    @keyword("Select Room Type")
    def select_room_type(self,room_id):
        page = PlaywrightCore.page

        #page.pause()
        # XPath to locate the specific "Book now" button
        book_locator = f"(//a[contains(@class, 'btn') and contains(@class, 'btn-primary') and normalize-space(text())='Book now'])[1]"
        #book_locator = f"(//a[contains(@class, 'btn') and contains(@class, 'btn-primary') and normalize-space(text())='Book now'])[{room_id}]"
        # Wait for the button to be visible
        #page.wait_for_selector(book_locator)
        # Click the button
        page.wait_for_timeout(1000)
        page.click(book_locator)

        # # Find all Book now buttons and click them based on index
        # book_now_buttons = page.locator("a.btn.btn-primary").filter(has_text=re.compile(r"Book now$"))
        # #count = book_now_buttons.count()
        # #logger.console(count)
        # x = 1
        # for button in book_now_buttons.all():
        #     #logger.console(expect(button).to_contain_text("Book now"))
        #     button.click()
        #     break
        #     x = x + 1

        page.wait_for_url("**/reservation/**")

        # book_locator = f"(//a[@class='btn btn-primary' and normalize-space()='Book now'])[{room_id}]"
        # #book_locator=f"(//a[@class='btn btn-primary' and normalize-space()='Book now'])[1]"
        # page.wait_for_selector(book_locator)
        # page.locator(book_locator).click()

        try:
            expect(page.get_by_role("button", name="Reserve Now")).to_contain_text("Reserve Now")
            page.get_by_role("button", name="Reserve Now").click()
            logger.info("Clicked on Book Now")
        except Exception as e:
            raise RuntimeError(f"Failed to Select any room: {str(e)}")


        # page.get_by_role("heading", name=room_type).click()
        # page.locator("div").filter(has_text=re.compile(rf"^{room_type}.*Book now$")).get_by_role("link").click()
        # page.get_by_role("heading", name="Book This Room").click()


    @keyword("Fill Reservation Details")
    def fill_reservation_details(self, firstname, lastname, email, phone):
        page = PlaywrightCore.page
        page.get_by_role("textbox", name="Firstname").fill(firstname)
        page.get_by_role("textbox", name="Lastname").fill(lastname)
        page.get_by_role("textbox", name="Email").fill(email)
        page.get_by_role("textbox", name="Phone").fill(phone)
        logger.info("Reservation details entered")
        #logger.console("Reservation details entered")


    @keyword("Confirm Reservation")
    def confirm_reservation(self):
        page = PlaywrightCore.page
        page.get_by_role("button", name="Reserve Now").click()
        for _ in range(1):
            page.keyboard.press("PageUp")
            page.wait_for_timeout(500)

        logger.info("clicked on confirm reservation")
        #logger.console("clicked on confirm reservation")
        expect(page.locator("//h2[normalize-space()='Booking Confirmed']")).to_contain_text("Booking Confirmed")
        logger.info("Booking confirmation validated")
        #logger.console("booking confirmation validated")


    @keyword("Send Us a Message")
    def send_us_a_message(self, name, email, phone_no, subject, description):
        page = PlaywrightCore.page
        page.get_by_test_id("ContactName").click()
        page.get_by_test_id("ContactName").fill(name)
        page.get_by_test_id("ContactEmail").click()
        page.get_by_test_id("ContactEmail").fill(email)
        page.get_by_test_id("ContactPhone").click()
        page.get_by_test_id("ContactPhone").fill(phone_no)
        page.get_by_test_id("ContactSubject").click()
        page.get_by_test_id("ContactSubject").fill(subject)
        page.get_by_test_id("ContactDescription").click()
        page.get_by_test_id("ContactDescription").fill(description)
        page.get_by_role("button", name="Submit").click()
        #page.pause()
        expect(page.get_by_role("heading", name="Thanks for getting in touch")).to_be_visible()
        expect(page.locator("#contact")).to_contain_text("Thanks for getting in touch " + name + "!")


#==========================================================================


    @keyword("Select Dates For Booking")
    def select_dates_for_booking(self, checkin_date=None, checkout_date=None):
        page = PlaywrightCore.page
        # for _ in range(1):
        #     page.keyboard.press("PageDown")
        #     page.wait_for_timeout(500)

        from datetime import datetime
        def format_date_verbose(date_str):
            """
            Converts a date string in 'YYYY-MM-DD' format to 'Weekday, DD Month' format.
            Parameters:
                date_str (str): Date string in 'YYYY-MM-DD' format.
            Returns:
                str: Formatted date string like 'Friday, 14 November'.
            """
            try:
                date_obj = datetime.strptime(date_str, "%Y-%m-%d")
                return date_obj.strftime("Choose %A, %d %B")
            except ValueError:
                return "Invalid date format. Please use 'YYYY-MM-DD'."

        checkin_date = format_date_verbose(checkin_date)
        checkout_date = format_date_verbose(checkout_date)

        # # Locate the Check in and Check out fields and enter date
        # page.locator("div").filter(has_text=re.compile(r"^Check In$")).get_by_role("textbox").fill("20/10/2025")
        # page.locator("div").filter(has_text=re.compile(r"^Check Out$")).get_by_role("textbox").fill("25/10/2025")
        page.locator("div").filter(has_text=re.compile(r"^Check In$")).get_by_role("textbox").click()
        page.get_by_role("button", name="Next Month").click()
        page.get_by_role("option", name=checkin_date).click()
        logger.info("CheckIn Date selected as : "+checkin_date)
        page.locator("div").filter(has_text=re.compile(r"^Check Out$")).get_by_role("textbox").click()
        page.get_by_role("button", name="Next Month").click()
        page.get_by_role("option", name=checkout_date).click()
        logger.info("CheckIn Date selected as : " +checkout_date)
        page.get_by_role("button", name="Check Availability").click()
        logger.info("Clicked on checked availability")
        #logger.console("Clicked on checked availability")
        #Validate availability result

    @keyword("Add New HotelRoom")
    def add_new_hotel_room(self):
        page = PlaywrightCore.page
        page.get_by_test_id("roomName").click()
        page.get_by_test_id("roomName").fill("104")
        page.locator("#type").select_option("Family")
        page.locator("#accessible").select_option("true")
        # page.locator("#roomPrice").click()
        page.locator("#roomPrice").fill("550")
        page.get_by_role("checkbox", name="WiFi").check()
        page.get_by_role("checkbox", name="TV").check()
        page.get_by_role("checkbox", name="Safe").check()
        page.get_by_role("checkbox", name="Views").check()
        page.get_by_role("button", name="Create").click()
        page.locator("div").filter(has_text=re.compile(r"^104$")).click()
        page.get_by_role("heading", name="Room:").click()
        expect(page.get_by_role("heading")).to_contain_text("Room: 104")
        page.get_by_text("Family").click()
        expect(page.locator("#root-container")).to_contain_text("Family")
        page.get_by_text("550").click()
        expect(page.locator("#root-container")).to_contain_text("550")
