*** Settings ***
Library         ../resources/PlaywrightCore.py
Resource        ../resources/Variables.robot
Library         RESTLibrary
Library         Collections
Library         BuiltIn
Library         RequestsLibrary

*** Variables ***
${TARGET_NAME}=  James Dean
#${checkin}=         2025-11-15
#${checkout}=        2025-11-16
##${ADMIN_USER}       admin
##${ADMIN_PASS}       password
#${FIRSTNAME}        Sourabh
#${LASTNAME}         Kumar
#${EMAIL}            sourabh@gmail.com
#${PHONE}            09988776655
${room_id}          1

*** Test Cases ***

Positive Scenario: Send a inquiry messages from UI
    skip
    Launch Browser Application    firefox
    Login As Admin          # ${ADMIN_USER}    ${ADMIN_PASS}
    Go Back To Front Page
    Send Us a Message    ${name}    ${EMAIL}    ${PHONE}    ${subject}  ${description}

Positive Scenario: Validate messages from APIs
    skip
    ${requestInfo}=   Make HTTP Request
    ...    get all messages
    ...    https://automationintesting.online/api/message
    ${name_api}=   Execute RC    <<<rc, get all messages, body,$.messages[*].name>>>
    should contain    ${name_api}    ${name}


Positive Scenario: Create booking from UI

   [Tags]    UI TestCase

    #${room_id}=    convert to integer    ${room_id}
    ${room_id}=   Execute RC    <<<rc, get all rooms, body,${JSON_QUERY}>>>
    #log to console    ====>> room id for booking from UI:- ${room_id}
    Launch Browser Application    firefox
    Login As Admin          # ${ADMIN_USER}    ${ADMIN_PASS}
    Go Back To Front Page
    select_dates_for_booking        ${checkin}      ${checkout}
    log to console    '''''${room_id}
    Select Room Type    {room_id}
    Fill Reservation Details    ${FIRSTNAME}    ${LASTNAME}    ${EMAIL}    ${PHONE}
    Confirm Reservation
    Capture Screenshot
    Close Browser