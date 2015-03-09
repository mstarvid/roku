'********************************************************************
'**  Video Player Example Application - Main
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'********************************************************************
'testing version control
'testing version control take 2

Sub Main()
    
     'initialize theme attributes like titles, logos and overhang color
    initTheme()

    facade = CreateObject("roParagraphScreen")
    facade.AddParagraph("please wait...")
    facade.Show()
    ' leave facade on stack until app exits

    authorized = AuthUser()

    if authorized = "success"

        'prepare the screen for display and get ready to begin
        screen=preShowHomeScreen("", "")
        if screen=invalid then
            print "unexpected error in preShowHomeScreen"
            return
        end if

        'set to go, time to get started
        showHomeScreen(screen)

    else if authorized = "NR"

        d = CreateObject("roMessageDialog")
        dPort = CreateObject("roMessagePort")
        d.SetMessagePort(dPort)
        d.SetTitle("Account Error")
        d.SetText("Oops. It appears you do not have an active MorningStar Video account.")
        d.AddButton(1, "OK")
        d.Show()

        Wait(0, dPort)
        d.Close()

    else if authorized = "failure"

        d = CreateObject("roMessageDialog")
        dPort = CreateObject("roMessagePort")
        d.SetMessagePort(dPort)
        d.SetTitle("System Error")
        d.SetText("Oops. An unknown error has occurred. Please contact tech support for further assistance.")
        d.AddButton(1, "OK")
        d.Show()

        Wait(0, dPort)
        d.Close()

    else if authorized = "connectFail"

        d = CreateObject("roMessageDialog")
        dPort = CreateObject("roMessagePort")
        d.SetMessagePort(dPort)
        d.SetTitle("Internet Error")
		d.SetText("Oops. We are currently minor technical difficulties, but we are working hard to correct the problem. In the meantime, you can still watch our entire catalog at http://mstarvid.com.  Click on Blog and Reviews for updates. We apologize for the inconvenience. Please try again later.")
        'd.SetText("Oops. It appears you are having internet connectivity issues. Please check your internet connection and try again.")
        d.AddButton(1, "OK")
        d.Show()

        Wait(0, dPort)
        d.Close()        

    else if authorized = "NF"
        
    		'sec = CreateObject("roRegistrySection", "mstarvid") 
    		'd = CreateObject("roMessageDialog")
            'dPort = CreateObject("roMessagePort")
            'd.SetMessagePort(dPort)
            'd.SetText(sec.Read("deviceToken"))
            'print sec.Read("deviceToken")
            'd.AddButton(1, "OK")
            'd.Show()

            'Wait(0, dPort)
            'd.Close()

        showLinkScreen()

        'prepare the screen for display and get ready to begin
        screen=preShowHomeScreen("", "")
        if screen=invalid then
            print "unexpected error in preShowHomeScreen"
            return
        end if

        'set to go, time to get started
        showHomeScreen(screen)

    end if    

End Sub


'*************************************************************
'** Set the configurable theme attributes for the application
'** 
'** Configure the custom overhang and Logo attributes
'** Theme attributes affect the branding of the application
'** and are artwork, colors and offsets specific to the app
'*************************************************************

Sub initTheme()

    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangOffsetSD_X = "72"
    theme.OverhangOffsetSD_Y = "31"
    theme.OverhangSliceSD = "pkg:/images/Overhang_Background_SD.png"
    theme.OverhangLogoSD  = "pkg:/images/Overhang_Logo_SD.png"

    theme.OverhangOffsetHD_X = "125"
    theme.OverhangOffsetHD_Y = "35"
    theme.OverhangSliceHD = "pkg:/images/Overhang_Background_HD.png"
    theme.OverhangLogoHD  = "pkg:/images/Overhang_Logo_HD.png"

    theme.BackgroundColor = "#000000"

    app.SetTheme(theme)

End Sub

sub ShowLinkScreen()
  dt = CreateObject("roDateTime")

  ' create a roCodeRegistrationScreen and assign it a roMessagePort
  port = CreateObject("roMessagePort")
  screen = CreateObject("roCodeRegistrationScreen")
  screen.SetMessagePort(port)

  ' add some header text
  screen.AddHeaderText("Link Your Account")
  ' add some buttons
  screen.AddButton(1, "Get new code")
  screen.AddButton(2, "Free Trial")
  ' Add a short narrative explaining what this screen is
  screen.AddParagraph("Before you can enjoy the awesomeness that resides in this channel, you need to link that newfangled Roku to your MorningStar Video account.")
  screen.AddParagraph(" ")
  ' Focal text should give specific instructions to the user
  screen.AddFocalText("Log into your account, then go to www.mstarvid.com/index.php/linkyourroku and enter the following code:", "spacing-normal")

  ' display a retrieving message until we get a linking code
  screen.SetRegistrationCode("Retrieving...")
  screen.Show()

  ' get a new code
  linkingCode = GetLinkingCode()
  if linkingCode <> invalid
    screen.SetRegistrationCode(linkingCode.code)
  else
    screen.SetRegistrationCode("Failed to get code...")
  end if
 
  screen.Show()

  while true
    ' we want to poll the API every 15 seconds for validation,
    ' so set a 15000 millisecond timeout on the Wait()
    msg = Wait(15000, screen.GetMessagePort())
   
    if msg = invalid
      ' poll the API for validation
      if ValidateLinkingCode(linkingCode.code)
        ' if validation succeeded, close the screen
        exit while
      end if

      dt.Mark()
      if dt.AsSeconds() > linkingCode.expires
        ' the code expired. display a message, then get a new one
        d = CreateObject("roMessageDialog")
        dPort = CreateObject("roMessagePort")
        d.SetMessagePort(dPort)
        d.SetTitle("Code Expired")
        d.SetText("This code has expired. Press OK to get a new one")
        d.AddButton(1, "OK")
        d.Show()

        Wait(0, dPort)
        d.Close()
        screen.SetRegistrationCode("Retrieving...")
        screen.Show()

        linkingCode = GetLinkingCode()
        if linkingCode <> invalid
          screen.SetRegistrationCode(linkingCode.code)
        else
          screen.SetRegistrationCode("Failed to get code...")
        end if
        screen.Show()
      end if
    else if type(msg) = "roCodeRegistrationScreenEvent"
      if msg.isScreenClosed()
        'exit while
        end
      else if msg.isButtonPressed()
        if msg.GetIndex() = 1
          ' the user wants a new code
          code = GetLinkingCode()
          linkingCode = GetLinkingCode()
          if linkingCode <> invalid
            screen.SetRegistrationCode(linkingCode.code)
          else
            screen.SetRegistrationCode("Failed to get code...")
          end if
          screen.Show()
        else if msg.GetIndex() = 2
            d = CreateObject("roMessageDialog")
            dPort = CreateObject("roMessagePort")
            d.SetMessagePort(dPort)
            d.SetTitle("Free Trial Details")
            d.SetText("Thanks for choosing MorningStar! Go to www.mstarvid.com/ to sign up for a 1-week free trial.")
            d.AddButton(1, "OK")
            d.Show()

            Wait(0, dPort)
            d.Close()
            end
          exit while
        end if
      end if
    end if
  end while
 
  screen.Close()
end sub

function ValidateLinkingCode(linkingCode)
  result = false

  xfer = CreateObject("roURLTransfer")
  xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
  xfer.AddHeader("X-Roku-Reserved-Dev-Id", "")
  xfer.InitClientCertificates()
  xfer.SetURL("https://mstarvid.com/validate_roku_code.php?check_code=true&code=" + linkingCode)
  response = xfer.GetToString()
  xml = CreateObject("roXMLElement")
  if xml.Parse(response)
    if UCase(xml.status.GetText()) = "SUCCESS"
      sec = CreateObject("roRegistrySection", "mstarvid")      
      sec.Delete("deviceToken")
      sec.Delete("user_id")
      sec.Write("deviceToken", xml.deviceToken.GetText())
      sec.Write("user_id", xml.user_id.GetText())
      sec.Flush()

      result = true
            d = CreateObject("roMessageDialog")
            dPort = CreateObject("roMessagePort")
            d.SetMessagePort(dPort)

            d.SetTitle("Success!")
            d.SetText("Your Roku has been linked to your MorningStar Video account.")
            d.AddButton(1, "OK")
            d.Show()

            Wait(0, dPort)
            d.Close()
    end if
  end if

  return result
end function

function GetLinkingCode()
  result = invalid

  xfer = CreateObject("roURLTransfer")
  xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
  xfer.AddHeader("X-Roku-Reserved-Dev-Id", "")
  xfer.InitClientCertificates()
  xfer.SetURL("http://mstarvid.com/get_roku_code.php?getcode=true")
  response = xfer.GetToString()
  xml = CreateObject("roXMLElement")
  if xml.Parse(response)
    result = {
      code: xml.linkingCode.GetText()
      expires: StrToI(xml.linkingCode@expires)
    }
  end if

  return result
end function

function AuthUser()

  sec = CreateObject("roRegistrySection", "mstarvid")
  device_token = sec.Read("deviceToken")
  user_id = sec.Read("user_id")

  xfer = CreateObject("roURLTransfer")
  xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
  xfer.AddHeader("X-Roku-Reserved-Dev-Id", "")
  xfer.InitClientCertificates()
  xfer.SetURL("https://mstarvid.com/roku_user_auth.php?auth=true&device_token=" + device_token + "&user_id=" + user_id)
  response = xfer.GetToString()
  xml = CreateObject("roXMLElement")

  print response

  if xml.Parse(response)

    if UCase(xml.status.GetText()) = "SUCCESS"
      result = "success"
    else if UCase(xml.status.GetText()) = "NR"
      result = "NR" 
    else if UCase(xml.status.GetText()) = "FAILURE"
      result = "failure"   
    else if UCase(xml.status.GetText()) = "NF"
      result = "NF"       
    end if

  else

    result = "connectFail"

    print UCase(xml.status.GetText())

  end if
return result
end function
