::------------------------------------------------------------------------------
:: NAME
::     gct.bat - A generic commodity trading simulation game
::
:: DESCRIPTION
::     Trade generic commodities in generic locations to make money.
::
:: HISTORY
::     I found an previous, incomplete version of this script from 2017 on an
::     old laptop and felt that it needed to be rewritten.
::------------------------------------------------------------------------------
@echo off
setlocal enabledelayedexpansion

echo [?25l
mode con cols=120 lines=25

call :varInit
call :resetItemPrices
call :storySplash

call :mainMenu
echo [?25h
exit /b

::------------------------------------------------------------------------------
:: Initializes variables for the start of the game
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:varInit
set "location=0"
for /L %%A in (0,1,8) do set "cargo[%%A]=0"
set /a money=(%RANDOM% %% 3000) + 500
set "in_game_day=1"
set "in_game_time=1"
exit /b

::------------------------------------------------------------------------------
:: Sets base prices and port-specific modifiers for those prices
::
:: == BASE PRICES ==      == PRICE VARIATIONS ==    == MAX RANGES ==
::   C[0] = 25-50           P[0] = ±20                C[0] = 5-70
::   C[1] = 65-100          P[1] = ±50                C[1] = 15-150
::   C[2] = 115-175         P[2] = ±30                C[2] = 85-205
::   C[3] = 210-450         P[3] = ±120               C[3] = 90-570
::   C[4] = 550-1000        P[4] = ±500               C[4] = 50-1500
::   C[5] = 1050-1300       P[5] = ±250               C[5] = 800-1550
::   C[6] = 2000-5000       P[6] = ±1500              C[6] = 500-6500
::   C[7] = 5000-8500       P[7] = ±2000              C[7] = 3000-10500
::   C[8] = 8500-10000      P[8] = ±1500              C[8] = 7000-11500
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:resetItemPrices
for %%A in (
    "0   25    50"
    "1   65   100"
    "2  115   175"
    "3  210   450"
    "4  550  1000"
    "5 1050  1300"
    "6 2000  5000"
    "7 5000  8500"
    "8 8500 10000"
) do (
    for %%B in (
        "0   20"
        "1   50"
        "2   30"
        "3  120"
        "4  500"
        "5  250"
        "6 1500"
        "7 2000"
        "8 1500"
    ) do (
        call :generatePortPrices "%%~A" "%%~B"
    )
)
exit /b

::------------------------------------------------------------------------------
:: Takes a tuple containing commodity base price data and a tuple containing
:: port price variation and merges the two to create an element in the
:: port/commodity 2D array in the format !port_price[commodity][port]!.
::
:: Arguments: %1 - Base price data in the format "commodity_index min max"
::            %2 - Port price data in the format "port_index price_offset"
:: Returns:   None
::------------------------------------------------------------------------------
:generatePortPrices
for /f "tokens=1-5" %%C in ("%~1 %~2") do (
    set /a "base_price[%%C]=!RANDOM!%%(%%E-%%D+1)+%%D"
    set /a "port_offset[%%C][%%F]=!RANDOM!%%(%%G*2)+%%G"
    set /a "port_price[%%C][%%F]=!base_price[%%C]!+!port_offset[%%C][%%F]!"
)
exit /b

::------------------------------------------------------------------------------
:: Display the story, if applicable
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:storySplash
echo There's no story, you are just trying to make money by trading commodities.
pause
exit /b

::------------------------------------------------------------------------------
:: Prints the money/location header at the top of the screen
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:printHeader
cls
set "in_game_time=00!in_game_hour!"
set "in_game_time=!in_game_time:~-2!:00"
echo  MONEY $!money! [1;54HDAY !in_game_day!, !in_game_time![1;109HLOCATION !location!
exit /b

::------------------------------------------------------------------------------
:: Core gameplay loop
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:mainMenu
call :printHeader
call :centerAndUnderline "GENERIC COMMODITY TRADER" 3
echo [5;48H 1. Check base prices
echo [6;48H 2. Go to the market
echo [7;48H 3. Check inventory
echo [8;48H 4. Move locations
echo [9;48H 5. Retire from trading
choice /c:12345 /n >nul

if "%errorlevel%"=="1" call :viewBasePrices
if "%errorlevel%"=="2" call :market
if "%errorlevel%"=="3" call :inventory
if "%errorlevel%"=="4" call :relocate
if "%errorlevel%"=="5" exit /b

:: An %errorlevel% of 6 means that the player won at the market
if "%errorlevel%"=="6" goto :win
goto :mainMenu

::------------------------------------------------------------------------------
:: Displays the base prices for the commodities without port adjustments
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:viewBasePrices
call :generateBorder
call :centerAndUnderline "DAILY COMMODITY  PRICE TRADER" 3

for /L %%A in (0,1,8) do (
    set /a row=%%A+5
    echo [!row!;29H^| Commodity #%%A
    call :bufferBuilder !base_price[%%A]!
    echo [!row!;!errorlevel!H $!base_price[%%A]!
)
pause >nul
exit /b

::------------------------------------------------------------------------------
:: Creates a border for displaying the trader sheet and the inventory
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:generateBorder
cls
echo [1;29H+------------------------------------------------------------+
for /L %%A in (2,1,14) do echo [%%A;29H^|[%%A;90H^|
echo [15;29H+------------------------------------------------------------+
exit /b

::------------------------------------------------------------------------------
:: Builds a string of periods as a buffer so that prices can be right-justified
::
:: Arguments: %1 - Either price or quantity of commodity
:: Returns:   The row index where the buffer ends
::------------------------------------------------------------------------------
:bufferBuilder
set "buffer_length=44"
:: This would be much more elegant if I could use log10()
if %~1 GEQ 10 set /a buffer_length-=1
if %~1 GEQ 100 set /a buffer_length-=1
if %~1 GEQ 1000 set /a buffer_length-=1
if %~1 GEQ 10000 set /a buffer_length-=1
if %~1 GEQ 100000 set /a buffer_length-=1
if %~1 GEQ 1000000 set /a buffer_length-=1

set "buffer="
for /L %%A in (1,1,!buffer_length!) do set "buffer=!buffer!."
REM set "buffer=!buffer! $!base_price[%~1]!"

echo [!row!;44H!buffer!
set /a buffer_end=42+!buffer_length!
exit /b !buffer_end!

::------------------------------------------------------------------------------
:: Allows the player to buy and sell commodities at the market
::
:: Arguments: None
:: Returns:   0 to prevent previous menus from triggering
::            5 if the player has won
::------------------------------------------------------------------------------
:market
call :printHeader
call :centerAndUnderline "MARKET" 3
echo [5;38H 1. Check local prices
echo [6;38H 2. Buy commodities
echo [7;38H 3. Sell commodities
echo [8;38H 4. Leave the market
choice /c:1234 /N >nul

if "%errorlevel%"=="1" call :showPrices & pause
if "%errorlevel%"=="2" call :transaction "-"
if "%errorlevel%"=="3" call :transaction "+"
if "%errorlevel%"=="4" exit /b 0
call :checkWinCondition && exit /b 6
goto :market

::------------------------------------------------------------------------------
:: Shows the current prices for goods based on current location
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:showPrices
call :printHeader
for /L %%A in (0,1,8) do echo %%A. Commodity %%A: $!port_price[%location%][%%A]!
exit /b

::------------------------------------------------------------------------------
:: Buy or sell items and update the inventory and money accordingly
::
:: Arguments: %1 - The operation that should be done to the user's money
:: Returns:   0 to reset the errorlevel so that a previous menu is not triggered
::------------------------------------------------------------------------------
:transaction
if "%~1"=="-" (
    set "transaction_verb=buy"
    set "transaction_noun=money"
    set "item_operator=+"
) else (
    set "transaction_verb=sell"
    set "transaction_noun=of that item"
    set "item_operator=-"
)

call :showPrices
echo N. Leave
echo.
choice /c:012345678N /M "Either %transaction_verb% something or leave: " /N
if "%errorlevel%"=="10" exit /b
set /a item_index=%errorlevel% - 1

:transactionLoop
set /p "quantity=How many of this item do you want to %transaction_verb%? "
call :verifyPositiveInteger "%quantity%"
if "%errorlevel%"=="1" (
    echo Invalid number. Please enter a positive integer.
    goto :transactionLoop
)
call :%transaction_verb%Validation "%item_index%" "%quantity%"
if "%errorlevel%"=="1" (
    echo You do not have enough %transaction_noun%.
    goto :transactionLoop
)

:: This is going to look weird because %1 is either + or -
set /a money=!money! %~1 !total_value!
set /a cargo[%item_index%]=!cargo[%item_index%]! %item_operator% %quantity%
exit /b 0

::------------------------------------------------------------------------------
:: Confirms that the user entered a positive integer
::
:: Arguments: %1 - The value to check for /[^0123456789]/
:: Returns:   0 if the argument is a positive integer
::            1 if the user included letters or punctuation
::------------------------------------------------------------------------------
:verifyPositiveInteger
set "is_int=0"
for /f "delims=0123456789" %%A in ("%~1") do set "is_int=1"
exit /b %is_int%

::------------------------------------------------------------------------------
:: Validates that the user has enough money to complete a purchase
::
:: Arguments: %1 - The index of the item to buy
::            %2 - The desired number of items to buy
:: Returns:   0 if the transaction can go through
::            1 if the user can not afford the purchase
::------------------------------------------------------------------------------
:buyValidation
set "transaction_ok=0"
set /a total_value=!port_price[%location%][%~1]! * %~2
if !total_value! GTR !money! set "transaction_ok=1"
exit /b %transaction_ok%

::------------------------------------------------------------------------------
:: Validates that the user has enough of an item in their inventory to sell
::
:: Arguments: %1 - The index of the item to sell
::            %2 - The desired number of items to sell
:: Returns:   0 if the transaction can go through
::            1 if the user does not have enough stock to sell
::------------------------------------------------------------------------------
:sellValidation
set "transaction_ok=0"
set "total_value=0"
if %~2 GTR !cargo[%~1]! (
    set "transaction_ok=1"
) else (
    set total_value=!port_price[%location%][%~1]! * %~2
)
exit /b %transaction_ok%

::------------------------------------------------------------------------------
:: Displays the inventory
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:inventory
call :generateBorder
call :centerAndUnderline "INVENTORY" 3

for /L %%A in (0,1,8) do (
    set /a row=%%A+5
    echo [!row!;31HCommodity %%A
    call :bufferBuilder !cargo[%%A]!
    echo [!row!;!errorlevel!H !cargo[%%A]!
)
pause >nul
exit /b

::------------------------------------------------------------------------------
:: Move to a new port where prices will be different (hopefully)
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:relocate
call :printHeader
call :centerAndUnderline "TRAVEL TO A NEW PORT" 3
for /L %%A in (0,1,8) do (
    set /a row=%%A+5
    echo [!row!;55H%%A. Port %%A
)
choice /C:012345678 /N >nul

set /a new_location=%errorlevel%-1, travel_distance=new_location-location
if "!travel_distance:~0,1!"=="-" set "travel_distance=!travel_distance:~1!"
set "location=%new_location%"

set /a in_game_hour+=travel_distance
if !in_game_hour! GEQ 24 (
    set /a in_game_hour=!in_game_hour! %% 24
    set /a in_game_day+=1
    call :resetItemPrices
)

echo Travelling to port %new_location%
timeout /t %travel_distance% >nul
exit /b

::------------------------------------------------------------------------------
:: Check to see if the player has crossed the $MAX_INT threshold
::
:: Arguments: None
:: Returns:   0 if the player is either exactly at MAX_INT or a negative value
::            1 if the game is not done yet
::------------------------------------------------------------------------------
:checkWinCondition
set "win_game=1"
if %money% GEQ 2147483647 set "win_game=0"
if %money% LSS 0 set "win_game=0"
exit /b %win_game%

::------------------------------------------------------------------------------
:: Displays the "You Win" text
::
:: Arguments: None
:: Returns:   None
::------------------------------------------------------------------------------
:win
echo After reaching $2^^31, you have acquired all possible money.
pause
exit /b

::------------------------------------------------------------------------------
:: Centers a string and draws a line of dashes underneath it
::
:: Arguments: %1 - The string to center and underline
::            %2 - The row to place the string on
:: Returns:   None
::------------------------------------------------------------------------------
:centerAndUnderline
call :strLen "%~1"
set /a center_col=(120-!errorlevel!)/2
echo [%~2;!center_col!H[4m%~1[0m
exit /b

::------------------------------------------------------------------------------
:: Gets the length of a string
::
:: Arguments: %1 - The string to calculate the length of
:: Returns:   The 1-indexed length of the string
:: Based on: https://www.dostips.com/DtTipsStringOperations.php#Function.strLen
::------------------------------------------------------------------------------
:strLen
set "str=A%~1"
set "len=0"
for /L %%A in (12,-1,0) do (
    set /a "len|=1<<%%A"
    for %%B in (!len!) do if "!str:~%%B,1!"=="" set /a "len&=~1<<%%A"
)
exit /b !len!