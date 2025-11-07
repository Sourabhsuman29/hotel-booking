*** Settings ***
Library         RESTLibrary
Library         collections
Library    RESTLibrary
Library    Collections

*** Variables ***
${username}=    deepak
${password}=    Pass1

*** Test Cases ***
Get All Users
      # this request will be processed using given authType, username and password, custom auth is implemented using a robot keyword in "Keywords" secction
      Make HTTP Request   get all users with custom auth    https://reqres.in/api/users?page=1      authType=set my auth token        username=dchourasia     password=Password1

*** Keywords ***
set my auth token
    [Arguments]  ${request info}
    # here is the example how you can update the url to include custom auth token for your request
    ${request info.url}=    Set Variable    ${request info.url}&token=customAuthToken

    # here is the example how you can update the request headers to include custom auth token for your request
    &{Headers}=    Set To Dictionary   ${request info.requestHeaders}      customAuthHeaderName=customAuthToken

    # return final requestInfo object after all the updates
    [Return]  ${request info}