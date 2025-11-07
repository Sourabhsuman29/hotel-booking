*** Settings ***
Library         ../resources/PlaywrightCore.py
Resource        ../resources/Variables.robot
Library         RESTLibrary
Library         Collections
Library         BuiltIn

*** Keywords ***
Pick Random Room from List
    [Arguments]    ${rooms}    ${total}
    ${rand_index}=    Evaluate    random.randint(0, ${total}-1)    random
    ${random_room}=   Get From List    ${rooms}    ${rand_index}
    RETURN    ${random_room}

*** Test Cases ***
Positive Scenario: Send a inquiry messages from UI

    Launch Browser Application    firefox
    Login As Admin          # ${ADMIN_USER}    ${ADMIN_PASS}
    Go Back To Front Page
    Send Us a Message    ${name}    ${EMAIL}    ${PHONE}    ${subject}  ${description}
    Close Browser

Positive Scenario: Validate messages from APIs
    ${requestInfo}=   Make HTTP Request
    ...    get all messages
    ...    https://automationintesting.online/api/message
    ${name_api}=   Execute RC    <<<rc, get all messages, body,$.messages[*].name>>>
    should contain    ${name_api}    ${name}

Positive Scenario: Get available hotel rooms details
    [Tags]    API TestCase
    ${requestInfo}=   Make HTTP Request
    ...    get all rooms
    ...    https://automationintesting.online/api/room?checkin=${checkin}&checkout=${checkout}
#    log to console  Response Code: ${requestInfo.responseStatusCode}
#    Log     Response Code: ${requestInfo.responseStatusCode}
#    Log     Response Body: ${requestInfo.responseBody}
     ${room_id}=   Execute RC    <<<rc, get all rooms, body,${JSON_QUERY}>>>
#     ${room_id} =    Execute RC    <<<rc, get all rooms, body,$.rooms[0]>>>


##=======Setting globa variable======================================================
    ${room_id}=    Set Variable    ${room_id}
    Set Global Variable    ${room_id}
##==============================================================
#-----------------------------------------------------------------------------------
Positive Scenario: Create booking from UI

    [Tags]    UI TestCase
    ${room_id}=   Execute RC    <<<rc, get all rooms, body,${JSON_QUERY}>>>
    log to console    ====>> Using RC room id for booking from UI: ${room_id}
    #${room_id}=    convert to integer    ${room_id}
    Launch Browser Application    firefox
    #Login As Admin     ${ADMIN_USER}    ${ADMIN_PASS}
    Login As Admin
    Go Back To Front Page
   # Select Dates        ${checkin}      ${checkout}
    Select Dates For Booking     ${checkin}      ${checkout}
    Select Room Type     ${room_id}
    Fill Reservation Details    ${FIRSTNAME}    ${LASTNAME}    ${EMAIL}    ${PHONE}
    Confirm Reservation
    Capture Screenshot
    Close Browser
#check available room
Positive Scenario: Check available rooms after booking

    [Tags]    API TestCase
    ${requestInfo}=    Make HTTP Request
    ...    get all rooms
    ...    https://automationintesting.online/api/room?checkin=${checkin}&checkout=${checkout}
#    Log     Response Code: ${requestInfo.responseStatusCode}
#    Log     Response Body: ${requestInfo.responseBody}
    ${data}=    Evaluate    json.loads("""${requestInfo.responseBody}""")    json
    ${rooms}=   Get From Dictionary    ${data}    rooms
    ${total}=   Get Length    ${rooms}
    Log To Console      available rooms in hotel after booking : ${total}

Positive Scenario: Get available hotel rooms details after booking from UI

    [Tags]    API TestCase
    ${requestInfo}=   Make HTTP Request
    ...    get all rooms
    ...    https://automationintesting.online/api/room?checkin=${checkin}&checkout=${checkout}
    log to console  Response Code: ${requestInfo.responseStatusCode}

    ${data}=    Evaluate    json.loads("""${requestInfo.responseBody}""")    json
    ${rooms}=   Get From Dictionary    ${data}    rooms
    ${total}=   Get Length    ${rooms}
    log             Before Booking- Total available rooms in hotel: ${total}
    Log To Console      available rooms in hotel after booking : ${total}

    #==============================================================
    Run Keyword If    ${total} == 0
    ...    Fail    No rooms available in JSON Response, Check for other date.
    #===============================================================
    ${random_room}=   Pick Random Room from List    ${rooms}    ${total}
    log               random room details : ${random_room}
    # evalustion dict using python
    ${random_room}=    Evaluate    dict(${random_room})
    ${room_id}=    Get From Dictionary    ${random_room}    roomid
    Log To Console    Picked random room id: ${room_id}
    #${room_id}     convert to integer    ${room_id}
    log to console    Evaluate    type(${room_id})
    ${room_id}     convert to integer    ${room_id}
    #log to console    Evaluate    type(${room_id})

    ${room_type}=    Get From Dictionary    ${random_room}    type
    log    selected room type for boking : ${room_type}
    ${room_id}=    Set Variable    ${room_id}
    Set Global Variable    ${room_id}
##test case for post request
Positive scenario : Create another new booking from API

      log to console    ===> global room id ${room_id}
      ${requestInfo}=  Make HTTP Request
      ...   create a new booking
      ...   https://automationintesting.online/api/booking
      ...   method=POST
      ...   requestBody={"roomid": ${room_id},"firstname":"Sourabh","lastname":"Kumar","depositpaid":false,"bookingdates":{"checkin":"${checkin}","checkout":"${checkout}"},"email":"sourabhsuman29@gmail.com","phone":"09576573031"}
      ...   expectedStatusCode=201
      ...   responseVerificationType=Partial
      ...   requestHeaders={'Content-Type' : 'application/json', 'Accept' : 'application/json','x-api-key': ''}
      # 'x-api-key': ''
     Log To Console     Response Code: ${requestInfo.responseStatusCode}


##Test Case for post request
Negative scenarios: create booking with wrong payload data

    [Tags]    API TestCase
      ${requestInfo}=  Make HTTP Request
      ...   create a new booking
      ...   https://automationintesting.online/api/booking
      ...   method=POST
      ...   requestBody={"roomid": ${room_id},"firstname":"Sourabh","lastname":"Kumar","depositpaid":false,"bookingdates":{"checkin":"${checkin}","checkout":"${checkout}"},"email":"sourabhsuman29@gmail.com","phone":"09576573031"}
      ...   expectedStatusCode=409
      ...   responseVerificationType=Partial
      ...   requestHeaders={'Content-Type' : 'application/json', 'Accept' : 'application/json','x-api-key': ''}
      # 'x-api-key': ''
     Log To Console     Response Code: ${requestInfo.responseStatusCode}

Positioe Scenario: Check available rooms after booking from API
    [Tags]    API TestCase
    ${requestInfo}=    Make HTTP Request
    ...    get all rooms
    ...    https://automationintesting.online/api/room?checkin=${checkin}&checkout=${checkout}
    Log     Response Code: ${requestInfo.responseStatusCode}
    Log     Response Body: ${requestInfo.responseBody}
    ${data}=    Evaluate    json.loads("""${requestInfo.responseBody}""")    json
    ${rooms}=   Get From Dictionary    ${data}    rooms
    ${total}=   Get Length    ${rooms}
    Log To Console      available rooms in hotel after booking : ${total}

Positive Scenario: Adding new hotel room
    [Tags]    UI TestCase
    Launch Browser Application    firefox
    Login As Admin
    Add New HotelRoom

Positioe Scenario: Check available rooms after adding new room in the hotelbooking
    [Tags]    API TestCase
    ${requestInfo}=    Make HTTP Request
    ...    get all rooms
    ...    https://automationintesting.online/api/room?checkin=${checkin}&checkout=${checkout}
    Log     Response Code: ${requestInfo.responseStatusCode}
    Log     Response Body: ${requestInfo.responseBody}
    ${data}=    Evaluate    json.loads("""${requestInfo.responseBody}""")    json
    ${rooms}=   Get From Dictionary    ${data}    rooms
    ${total}=   Get Length    ${rooms}
    Log To Console      available rooms in hotel after adding new room : ${total}
