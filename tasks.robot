*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
...

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.RobotLogListener
Library             RPA.Archive
Library             Dialogs
Library             RPA.HTTP
Library             OperatingSystem
Library             RPA.FileSystem


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the orders file
    ${data}=    Read order file
    Process Orders    ${data}
    ZIP File
    [Teardown]    Close Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Read order file
    ${data}=    Read table from CSV    ${CURDIR}${/}orders.csv    header=True
    RETURN    ${data}

Data entry for each order
    [Arguments]    ${row}
    Wait Until Page Contains Element    //button[@class="btn btn-dark"]
    Click Button    //button[@class="btn btn-dark"]
    Select From List By Value    //select [@name="head"]    ${row}[Head]
    Click Element    //input[@value="${row}[Body]"]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    //input[@placeholder="Shipping address"]    ${row}[Address]
    Click Button    //button[@id="preview"]
    Wait Until Page Contains Element    //div[@id="robot-preview-image"]
    Sleep    5 seconds
    Click Button    //button[@id="order"]
    Sleep    5 seconds

Process receipts
    [Arguments]    ${row}
    Wait Until Page Contains Element    //div[@class="alert alert-success"]
    ${receiptdata}=    Get Element Attribute    //div[@class="alert alert-success"]    outerHTML
    Html To Pdf    ${receiptdata}    ${CURDIR}${/}receipts${/}${row}[Order number].pdf
    Screenshot    //div[@id="robot-preview-image"]    ${CURDIR}${/}robots${/}${row}[Order number].png
    Add Watermark Image To Pdf
    ...    ${CURDIR}${/}robots${/}${row}[Order number].png
    ...    ${CURDIR}${/}receipts${/}${row}[Order number].pdf
    ...    ${CURDIR}${/}receipts${/}${row}[Order number].pdf
    Click Button    //button[@id="order-another"]

Process Orders
    [Arguments]    ${data}
    FOR    ${row}    IN    @{data}
        Data entry for each order    ${row}
        Check Receipt
        Process receipts    ${row}
    END

Check Receipt
    FOR    ${i}    IN    ${100}
        ${danger}=    Is Element Visible    //div[@class="alert alert-danger"]
        IF    '${danger}'=='True'    Click Button    //button[@id="order"]
        IF    '${danger}'=='False'    BREAK
    END

ZIP File
    Archive Folder With Zip    ${CURDIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.Zip
