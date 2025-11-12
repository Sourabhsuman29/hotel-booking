*** Settings ***
Library         RESTLibrary
Library         Collections
Library         BuiltIn

*** Variables ***
${checkin}=     2025-10-12
${checkout}=    2025-10-13
${room_id}
*** Keywords ***
Pick Random Room from List
    [Arguments]    ${rooms}    ${total}
    ${rand_index}=    Evaluate    random.randint(0, ${total}-1)    random
    ${random_room}=   Get From List    ${rooms}    ${rand_index}
    RETURN    ${random_room}

*** Test Cases ***
Get available hotel rooms details
    ${requestInfo}=    Make HTTP Request
    ...    get all rooms
    ...    https://automationintesting.online/api/room?checkin=${checkin}&checkout=${checkout}
    Log To Console     Response Code: ${requestInfo.responseStatusCode}
    Log To Console     Response Body: ${requestInfo.responseBody}

    ${data}=    Evaluate    json.loads("""${requestInfo.responseBody}""")    json
    ${rooms}=   Get From Dictionary    ${data}    rooms
    ${total}=   Get Length    ${rooms}
    Log To Console      Total available rooms in hotel: ${total}

    Run Keyword If    ${total} == 0
    ...    Fail    No rooms available in JSON.

    ${random_room}=   Pick Random Room from List    ${rooms}    ${total}
    Log To Console    Random room details: ${random_room}

    # evalustion dict using python
    ${random_room}=    Evaluate    dict(${random_room})

    ${room_id}=    Get From Dictionary    ${random_room}    roomid
    Log To Console    Picked random room ID: ${room_id}
    #${room_id}     convert to integer    ${room_id}
    log to console    Evaluate    type(${room_id})
    ${room_id}     convert to integer    ${room_id}
    log to console    Evaluate    type(${room_id})

    ${room_type}=    Get From Dictionary    ${random_room}    type
    log    room type: ${room_type}
    ${room_id}=    Set Variable    ${room_id}
    Set Global Variable    ${room_id}
#Test Case for post request
Create New Hotel Booking
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

Check available rooms after booking
    ${requestInfo}=    Make HTTP Request
    ...    get all rooms
    ...    https://automationintesting.online/api/room?checkin=${checkin}&checkout=${checkout}

    Log To Console     Response Code: ${requestInfo.responseStatusCode}
    Log To Console     Response Body: ${requestInfo.responseBody}
    ${data}=    Evaluate    json.loads("""${requestInfo.responseBody}""")    json
    ${rooms}=   Get From Dictionary    ${data}    rooms
    ${total}=   Get Length    ${rooms}
    Log To Console      Total available rooms in hotel: ${total}