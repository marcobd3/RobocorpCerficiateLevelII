*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Desktop
Library           RPA.Archive
Library           OperatingSystem
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

Suite Teardown      Close All Browsers


*** Variables ***
${PDF_DIR}            ${OUTPUT_DIR}/PDFs/
${PNG_DIR}            ${OUTPUT_DIR}/PNGs/
${csv_url}    https://robotsparebinindustries.com/orders.csv

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${username}=    Ask for username
    Log    username

    ${secrets}=    Get secrets
    Open the robot order website    ${secrets}[robot_url]

    
    ${orders}=    Get rows    ${csv_url}

    FOR    ${order}    IN    @{orders}
        Fill the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    10x    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${order}[Order number]
        Go to order another robot
    END 

    Create a ZIP file of the receipts
    Remove Directory    ${PDF_DIR}    recursive=${True}
    Remove Directory    ${PNG_DIR}    recursive=${True}

    Close All Browsers
    Log    Finished


*** Keywords ***
Ask for username
    Add heading    Please provide URL to CSV file
    Add text input    name=url
    ${result}=    Run dialog
    RETURN    ${result.url}


Get secrets
    ${secret}=    Get Secret    credentials
    RETURN    ${secret}


Open the robot order website
    [Arguments]     ${robot_url}
    Open Available Browser    ${robot_url}
    Click Link    Order your robot!
    Click Button    OK


Get rows
    [Arguments]    ${csv_url}
    Download    ${csv_url}    overwrite=${True}
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}


Fill the form
    [Arguments]    ${order}
    Select From List By Value    id:head     ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    class:form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]


Preview the robot
    Click Button    id:preview


Submit the order
    Click Button    id:order
    Click Element    id:receipt


Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:parts    30s
    ${order_results_html}=    Get Element Attribute    id:parts    outerHTML
    ${order_results_pdf}=    Html To Pdf    ${order_results_html}    ${PDF_DIR}${/}${order_number}.pdf
    RETURN    ${order_results_pdf}


Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:robot-preview
    ${order_screenshot}=    Screenshot    id:robot-preview    ${PNG_DIR}${/}${order_number}.png
    RETURN    ${order_screenshot}


Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${order_number}
    Open Pdf    ${PDF_DIR}${/}${order_number}.pdf
    Add Watermark Image To Pdf    ${PNG_DIR}${/}${order_number}.png    ${PDF_DIR}${/}${order_number}.pdf
    Close Pdf


Go to order another robot
    Wait Until Page Contains Element    order-another
    Click Button    order-another
    Click Button    OK


Create a ZIP file of the receipts
    Archive Folder With Zip    ${PDF_DIR}    ${OUTPUT_DIR}/archive.zip
