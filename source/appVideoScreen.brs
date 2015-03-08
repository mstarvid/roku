'**********************************************************
'**  Video Player Example Application - Video Playback 
'**  November 2009
'**  Copyright (c) 2009 Roku Inc. All Rights Reserved.
'**********************************************************

'***********************************************************
'** Create and show the video screen.  The video screen is
'** a special full screen video playback component.  It 
'** handles most of the keypresses automatically and our
'** job is primarily to make sure it has the correct data 
'** at startup. We will receive event back on progress and
'** error conditions so it's important to monitor these to
'** understand what's going on, especially in the case of errors
'***********************************************************  
Function showVideoScreen(episode As Object)

    if type(episode) <> "roAssociativeArray" then
        print "invalid data passed to showVideoScreen"
        return -1
    endif

    port = CreateObject("roMessagePort")
    screen = CreateObject("roVideoScreen")
    screen.SetCertificatesFile("common:/certs/ca-bundle.crt")
    screen.AddHeader("X-Roku-Reserved-Dev-Id", "")
    screen.InitClientCertificates()
    screen.SetMessagePort(port)

    screen.SetPositionNotificationPeriod(30)
    screen.SetContent(episode)
    screen.Show()

    'Uncomment his line to dump the contents of the episode to be played
    PrintAA(episode)


    clock = CreateObject("roTimespan")
    next_call = clock.TotalMilliseconds() + 500

    playbackPaused = "false"
    buffering = "true"
    isAnEmployee = isEmployee()


    while true

        msg = wait(1, port)

        if type(msg) = "roVideoScreenEvent" then

            print "showHomeScreen | msg = "; msg.getMessage() " | index = "; msg.GetIndex()
            if msg.isScreenClosed()
                print "hello world (screen was closed)"
                exit while
            elseif msg.isRequestFailed()
                print "Video request failure: "; msg.GetIndex(); " " msg.GetData() 
            elseif msg.isStatusMessage()
                print "Video status: "; msg.GetIndex(); " " msg.GetData() 
            elseif msg.isButtonPressed()
                print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
            elseif msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
                RegWrite(episode.ContentId, nowpos.toStr())
            else
                print "Unexpected event type: "; msg.GetType()
            end if

        else

            print "Unexpected message class: "; type(msg)

        end if

        if type(msg) = "roVideoScreenEvent" then

            newMsg = msg.getMessage()

            if newMsg = "Playback paused." then
                
                playbackPaused = "true"   
                print "hello world (playeback paused)"
            
            end if

            if newMsg = "Playback resumed." then 

                playbackPaused = "false"
                clock.Mark()
                next_call = clock.TotalMilliseconds() + 500

            end if 

            if (newMsg = "HLS segment info") and buffering = "true" then
                
                buffering = "false"
                clock.Mark()
                next_call = clock.TotalMilliseconds() + 500
            
            end if

        end if    

        if (clock.TotalMilliseconds() > next_call) and (playbackPaused <> "true") and (buffering <> "true") and (isAnEmployee <> "true") then

            delta = clock.TotalMilliseconds() - next_call
            reportTime = 500 + delta
            next_call = clock.TotalMilliseconds() + 500
            ReportPlayback(episode.ContentId, reportTime.ToStr())

        end if

    end while

End Function

Function ReportPlayback(k2_id,timeViewed)

  xfer = CreateObject("roURLTransfer")
  xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
  xfer.AddHeader("X-Roku-Reserved-Dev-Id", "")
  xfer.InitClientCertificates()
  xfer.SetURL("https://mstarvid.com/roku_movie_view.php?k2_id="+k2_id+"&time_viewed="+timeViewed)
  response = xfer.GetToString()
  print "https://mstarvid.com/roku_movie_view.php?k2_id="+k2_id+"&time_viewed="+timeViewed
  xml = CreateObject("roXMLElement")
  if xml.Parse(response)
    if UCase(xml.status.GetText()) = "SUCCESS"
      
    end if
  end if

End Function

Function isEmployee()

  sec = CreateObject("roRegistrySection", "mstarvid")
  user_id = sec.Read("user_id")
    
  xfer = CreateObject("roURLTransfer")
  xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
  xfer.AddHeader("X-Roku-Reserved-Dev-Id", "")
  xfer.InitClientCertificates()
  xfer.SetURL("https://mstarvid.com/roku_movie_view.php?user_id="+user_id)
  response = xfer.GetToString()
  xml = CreateObject("roXMLElement")
  if xml.Parse(response)
    if UCase(xml.status.GetText()) = "EMPLOYEE"
        return "true"
    else
        return "false"      
    end if
  end if

End Function