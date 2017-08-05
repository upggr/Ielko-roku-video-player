'********************************************************************
'
'       NewVideoPlayer -- Example Multi-Level Roku Channel
'
' Copyright (c) 2015, belltown. All rights reserved. See LICENSE.txt
'
'********************************************************************

'
' To switch from using an roPosterScreen to an roGridScreen when displaying categories with leaves:
'   Change uiDisplayCategoryWithLeaves () to uiDisplayCategoryGrid () in two places:
'   uiDisplay () and uiDisplayCategoryWithoutLeaves ()
'

'
' Display the appropriate UI screen depending on the feed type
'
Function uiDisplay (contentItem As Object) As Void
    If contentItem.xxFeedType = "category"
        uiDisplayCategoryWithoutLeaves (contentItem)
    Else If contentItem.xxFeedType = "leaf"
      ' uiDisplayCategoryWithLeaves (contentItem.xxChildContentList, 0, contentItem.xxChildNamesList)
        uiDisplayCategoryGrid (contentItem.xxChildContentList, 0, contentItem.xxChildNamesList)
    Else If contentItem.xxFeedType = "feed"
        If Not contentItem.xxIsCached
            contentItem.xxChildContentList = parseXmlDocument (contentItem.xxFeedPath)
            contentItem.xxIsCached = True
        End If
        uiDisplayCategoryWithoutLeaves (contentItem.xxChildContentList)
    Else If contentItem.xxFeedType = "items"
        uiDisplayCategoryWithoutLeaves (contentItem)
    Else
        _debug ("uiDisplay. Invalid Feed Type: contentItem.xxFeedType")
    End If

End Function

Function uiDisplayCategoryWithoutLeaves (contentItem As Object, breadLeft = "" As String, breadRight = "" As String) As Void
    port = CreateObject ("roMessagePort")
    ui = CreateObject ("roPosterScreen")
    ui.SetMessagePort (port)
    ui.SetCertificatesFile ("common:/certs/ca-bundle.crt")
    ui.InitClientCertificates ()
    ui.SetBreadcrumbText (breadLeft, breadRight)
    ui.SetListStyle ("flat-category")
    ui.SetContentList (contentItem.xxChildContentList)
    ui.Show ()

    itemIndex = 0
    ui.SetFocusedListItem (0)

    While True
        msg = Wait (0, port) : _logEvent ("uiDisplayCategoryWithoutLeaves", msg)
        If msg <> Invalid
            If Type (msg) = "roPosterScreenEvent"
                If msg.IsScreenClosed ()
                    Exit While
                Else If msg.IsListItemSelected ()
                    itemIndex = msg.GetIndex ()
                    selectedContentItem = contentItem.xxChildContentList [itemIndex]

                    If selectedContentItem.xxFeedType = "category"
                        uiDisplayCategoryWithoutLeaves (selectedContentItem, breadRight, selectedContentItem.Title)

                    Else If selectedContentItem.xxFeedType = "leaf"
                        'uiDisplayCategoryWithLeaves (selectedContentItem, 0, breadRight, selectedContentItem.Title)
                        uiDisplayCategoryGrid (selectedContentItem, 0, breadRight, selectedContentItem.Title)

                    Else If selectedContentItem.xxFeedType = "feed"
                        If Not selectedContentItem.xxIsCached
                            selectedContentItem.xxChildContentList = parseXmlDocument (selectedContentItem.xxFeedPath)  ' Read <feed> node
                            selectedContentItem.xxIsCached = True
                        End If
                        uiDisplayCategoryWithoutLeaves (selectedContentItem.xxChildContentList, breadRight, selectedContentItem.Title)
                    Else
                        itemIndex = uiDisplayDetails (contentItem, itemIndex, breadRight, contentItem.Title)    ' Pass in <feed> element
                        ui.SetFocusedListItem (itemIndex)

                    End If
                End If
            End If
        End If
    End While
End Function
Function uiDisplayCategoryWithLeaves (contentItem As Object, nameIndex As Integer, breadLeft = "" As String, breadRight = "" As String) As Void
    port = CreateObject ("roMessagePort")
    ui = CreateObject ("roPosterScreen")
    ui.SetMessagePort (port)
    ui.SetCertificatesFile ("common:/certs/ca-bundle.crt")
    ui.InitClientCertificates ()
    ui.SetBreadcrumbText (breadLeft, breadRight)
    ui.SetListStyle ("flat-category")
    ui.SetListNames (contentItem.xxChildNamesList)
    feedContentItem = contentItem.xxChildContentList [nameIndex]
    If Not feedContentItem.xxIsCached
        contentItem.xxChildContentList [nameIndex] = parseXmlDocument (feedContentItem.xxFeedPath)
        feedContentItem = contentItem.xxChildContentList [nameIndex]
        feedContentItem.xxIsCached = True
    End If
    ui.SetContentList (feedContentItem.xxChildContentList)

    itemIndex = 0
    ui.SetFocusedListItem (itemIndex)
    ui.Show ()

    focusTimer = CreateObject ("roTimespan")
    focusTimerRunning = False
    listIndex = 0

    While True
        msg = Wait (10, port) : If msg <> Invalid Then _logEvent ("uiDisplayCategoryWithLeaves", msg)
        If (Type (msg) = "Invalid" And focusTimerRunning And focusTimer.TotalMilliseconds () > 750) Or (Type (msg) = "roPosterScreenEvent" And msg.IsListSelected () And msg.GetIndex () <> listIndex)
            focusTimerRunning = False
            ui.SetFocusedListItem (0)
            nameIndex = listIndex
            itemIndex = 0
            ui.SetFocusedListItem (itemIndex)
            feedContentItem = contentItem.xxChildContentList [nameIndex]
            If Not feedContentItem.xxIsCached
                contentItem.xxChildContentList [nameIndex] = parseXmlDocument (feedContentItem.xxFeedPath)
                feedContentItem = contentItem.xxChildContentList [nameIndex]
                feedContentItem.xxIsCached = True
            End If
            ui.SetContentList (feedContentItem.xxChildContentList)
            ui.ClearMessage ()
        Else If Type (msg) = "roPosterScreenEvent"
            If msg.IsScreenClosed ()
                Exit While

            Else If msg.IsListFocused ()
                ui.SetContentList ([])
                ui.ShowMessage ("Retrieving ...")
                listIndex = msg.GetIndex ()
                focusTimerRunning = True
                focusTimer.Mark ()
            Else If msg.IsListItemSelected ()
                ui.ClearMessage ()
                itemIndex = msg.GetIndex ()
                itemIndex = uiDisplayDetails (contentItem.xxChildContentList [nameIndex], itemIndex, breadRight, contentItem.xxChildNamesList [nameIndex])
                ui.SetFocusedListItem (itemIndex)
            End If
        End If
    End While
End Function

Function uiDisplayCategoryGrid (contentItem As Object, nameIndex As Integer, breadLeft = "" As String, breadRight = "" As String) As Void
    port = CreateObject ("roMessagePort")
    ui = CreateObject ("roGridScreen")
    ui.SetMessagePort (port)
    ui.SetCertificatesFile ("common:/certs/ca-bundle.crt")  ' Allow "https" images
    ui.InitClientCertificates ()
    ui.SetDisplayMode ("scale-to-fill")
    'ui.SetDisplayMode ("scale-to-fit")     ' Use this if the image dimensions appear too distorted with "scale-to-fill"
    ui.SetGridStyle ("flat-movie")          ' See the Component Reference for roGridScreen for all the styles available
    'ui.SetGridStyle ("flat-square")
    ui.SetupLists (contentItem.xxChildContentList.Count ())
    ui.SetListNames (contentItem.xxChildNamesList)
    ui.SetBreadcrumbText (breadLeft, breadRight)
    If _getRokuVersion ().IsLegacy
        ui.SetUpBehaviorAtTopRow ("exit")
    Else
        ui.SetUpBehaviorAtTopRow ("stop")
    End If

    feedContentItem = contentItem.xxChildContentList [nameIndex]
    If Not feedContentItem.xxIsCached
        contentItem.xxChildContentList [nameIndex] = parseXmlDocument (feedContentItem.xxFeedPath)
        feedContentItem = contentItem.xxChildContentList [nameIndex]
        feedContentItem.xxIsCached = True
    End If
    ui.SetContentList (nameIndex, contentItem.xxChildContentList [nameIndex].xxChildContentList)
    nextIndex = nameIndex + 1
    If nextIndex >= contentItem.xxChildContentList.Count ()
        nextIndex = nameIndex
    End If
    If nextIndex <> nameIndex
        nextContentItem = contentItem.xxChildContentList [nextIndex]
        If Not nextContentItem.xxIsCached
            contentItem.xxChildContentList [nextIndex] = parseXmlDocument (nextContentItem.xxFeedPath)  ' Read <feed> node
            nextContentItem = contentItem.xxChildContentList [nextIndex]
            nextContentItem.xxIsCached = True
        End If
        ui.SetContentList (nextIndex, nextContentItem.xxChildContentList)
    End If

    ui.SetFocusedListItem (nameIndex, 2)
    ui.Show ()

    While True
        msg = Wait (0, port) : _logEvent ("uiDisplayCategoryGrid", msg)
        If msg <> Invalid
            If Type (msg) = "roGridScreenEvent"
                If msg.IsScreenClosed ()
                    Exit While
                Else If msg.IsListItemFocused ()
                    nameIndex = msg.GetIndex ()
                    itemIndex = msg.GetData ()
                    feedContentItem = contentItem.xxChildContentList [nameIndex]

                    If Not feedContentItem.xxIsCached
                        contentItem.xxChildContentList [nameIndex] = parseXmlDocument (feedContentItem.xxFeedPath)
                        feedContentItem = contentItem.xxChildContentList [nameIndex]
                        feedContentItem.xxIsCached = True
                    End If

                    ui.SetContentList (nameIndex, feedContentItem.xxChildContentList)

                    nextIndex = nameIndex + 1
                    If nextIndex >= contentItem.xxChildContentList.Count ()
                        nextIndex = nameIndex
                    End If
                    If nextIndex <> nameIndex
                        nextContentItem = contentItem.xxChildContentList [nextIndex]
                        If Not nextContentItem.xxIsCached
                            contentItem.xxChildContentList [nextIndex] = parseXmlDocument (nextContentItem.xxFeedPath)
                            nextContentItem = contentItem.xxChildContentList [nextIndex]
                            nextContentItem.xxIsCached = True
                        End If
                        ui.SetContentList (nextIndex, nextContentItem.xxChildContentList)
                    End If

                Else If msg.IsListItemSelected ()
                    nameIndex = msg.GetIndex ()
                    itemIndex = msg.GetData ()
                    itemIndex = uiDisplayDetails (contentItem.xxChildContentList [nameIndex], itemIndex, breadRight, contentItem.xxChildNamesList [nameIndex])
                    ui.SetFocusedListItem (nameIndex, itemIndex)
                End If
            End If
        End If
    End While
End Function

Function uiDisplayDetails (feedContentItem As Object, index As Integer, breadLeft = "" As String, breadRight = "" As String) As Integer

    If feedContentItem.xxFeedContentType = "video"
        index = uiDisplayVideoDetails (feedContentItem.xxChildContentList, index, breadLeft, breadRight)
    Else
        uiSoftError ("uiDisplayDetails", LINE_NUM, "Unsupported Content Type: " + feedContentItem.xxFeedContentType)
    End If

    Return index

End Function


Function uiDisplayVideoDetails (contentList As Object, index As Integer, breadLeft = "" As String, breadRight = "" As String) As Integer
    port = CreateObject ("roMessagePort")
    ui = CreateObject ("roSpringboardScreen")
    ui.SetMessagePort (port)
    ui.SetCertificatesFile ("common:/certs/ca-bundle.crt")
    ui.InitClientCertificates ()
    ui.SetDisplayMode ("scale-to-fill")
    ui.SetDescriptionStyle ("movie")
    ui.SetBreadcrumbText (breadLeft, breadRight)
    uiDisplayVideoDetailsSetContent (ui, contentList, index)
    ui.Show ()

    While True
        msg = Wait (0, port) : _logEvent ("uiDisplayVideoDetails", msg)
        If msg <> Invalid
            If msg.IsScreenClosed ()
                Exit While
            Else If msg.IsButtonPressed ()
                buttonId = msg.GetIndex ()
                streams = contentList [index].LookupCI ("Streams")
                If streams <> Invalid And streams.Count () > 0
                    facade = CreateObject ("roImageCanvas")
                    facade.SetLayer (0, {Color: "#FF000000"})
                    facade.Show ()
                    If buttonId = 0
                        uiPlayVideo (contentList, index)
                        uiDisplayVideoDetailsSetContent (ui, contentList, index)
                    Else If buttonId = 1
                        While index < contentList.Count ()
                            streams = contentList [index].LookupCI ("Streams")
                            If streams <> Invalid And streams.Count () > 0
                                If Not uiPlayVideo (contentList, index)
                                    Exit While
                                End If
                            End If
                            index = index + 1
                            If index < contentList.Count ()
                                uiDisplayVideoDetailsSetContent (ui, contentList, index)
                            Else
                                index = contentList.Count () - 1
                                Exit While
                            End If
                        End While
                        uiDisplayVideoDetailsSetContent (ui, contentList, index)
                    Else If buttonId = 2
                        uiPlayVideo (contentList, index)
                        uiDisplayVideoDetailsSetContent (ui, contentList, index)
                    Else If buttonId = 3
                        If Not contentList [index].Live
                            _clearBookmark (contentList [index].ContentId)
                            contentList [index].Delete ("playstart")
                        End If
                        uiPlayVideo (contentList, index)
                        uiDisplayVideoDetailsSetContent (ui, contentList, index)
                    End If
                    facade.Close ()
                Else
                    uiSoftError ("uiDisplayVideoDetails", LINE_NUM, "No media streams found for this item")
                    uiDisplayVideoDetailsSetContent (ui, contentList, index)
                End If
            Else If msg.IsRemoteKeyPressed ()
                key = msg.GetIndex ()
                If key = 4
                    If index > 0
                        index = index - 1
                        uiDisplayVideoDetailsSetContent (ui, contentList, index)
                    End If
                Else If key = 5
                    If index < contentList.Count () - 1
                        index = index + 1
                        uiDisplayVideoDetailsSetContent (ui, contentList, index)
                    End If
                End If
            End If
        End If
    End While

    Return index

End Function

Function uiDisplayVideoDetailsSetContent (ui As Object, contentList As Object, index As Integer) As Void

    ui.AllowUpdates (False)
    ui.ClearButtons ()
    If contentList [index].Live Or _getBookmark (contentList [index].ContentId) < 10
        ui.AddButton (0, "Play")
        If contentList.Count () > 1 Then ui.AddButton (1, "Play all")
    Else
        ui.AddButton (2, "Resume")
        ui.AddButton (3, "Play from beginning")
        If contentList.Count () > 1 Then ui.AddButton (1, "Play all")
    End If
    ui.AllowNavLeft (contentList.Count () > 1)
    ui.AllowNavRight (contentList.Count () > 1)
    ui.SetStaticRatingEnabled (contentList [index].StarRating <> Invalid)
    ui.SetContent (contentList [index])
    ui.AllowUpdates (True)

End Function

Function uiPlayVideo (contentList As Object, index As Integer) As Boolean
    normalCompletion = False
    playTimer = CreateObject ("roTimespan")
    MAX_RETRIES = 2
    numRetries = 0

    If index >= 0 And index < contentList.Count ()

        done = False
        While Not done
            done = True

            port = CreateObject ("roMessagePort")
            ui = CreateObject ("roVideoScreen")
            ui.SetMessagePort (port)
            ui.SetCertificatesFile ("common:/certs/ca-bundle.crt")
            ui.InitClientCertificates ()
            If Not contentList [index].Live
                ui.SetPositionNotificationPeriod (10)
                playStart = _getBookmark (contentList [index].ContentId)
                If playStart >= 10
                    contentList [index].PlayStart = playStart
                End If
            End If
            If contentList [index].Live
                ui.SetPreviewMode (True)
            End If

            statusMessage = ""

            ui.SetContent (contentList [index])
            ui.Show ()

            While True
                msg = Wait (0, port) : _logEvent ("uiPlayVideo", msg)
                If msg <> Invalid

                    If msg.IsScreenClosed ()
                        Exit While
                    Else If msg.IsPlaybackPosition ()
                        If Not contentList [index].Live And msg.GetIndex () >= 10
                            _setBookmark (contentList [index].ContentId, msg.GetIndex ())
                        End If
                    Else If msg.IsStreamStarted ()
                        playTimer.Mark ()
                    Else If msg.IsFullResult ()
                        normalCompletion = True
                        If Not contentList [index].Live
                            _clearBookmark (contentList [index].ContentId)
                            contentList [index].Delete ("playstart")    ' Don't need PlayStart in the content list any more
                        End If
                    Else If msg.IsStatusMessage ()
                        statusMessage = msg.GetMessage ()
                    Else If msg.IsRequestFailed ()
                        failIndex = msg.GetIndex ()
                        message = msg.GetMessage ()
                        failMessage = ""
                        unsupportedMessage = ""
                        If message = ""
                            message = statusMessage
                        End If
                        If playTimer.TotalSeconds () > 300
                            numRetries = 0
                            playTimer.Mark ()
                        End If

                        numRetries = numRetries + 1

                        If numRetries > MAX_RETRIES Or failIndex = -4
                            If failIndex >= -5 And failIndex <= 0
                                failMessage = [ "Network error : server down or unresponsive, server is unreachable, network setup problem on the client.",
                                                "HTTP error: malformed headers or HTTP error result.",
                                                "Connection timed out.",
                                                "Unknown error.",
                                                "Empty list; no streams were specified to play.",
                                                "Media error; the media format is unknown or unsupported." ][-failIndex]
                                If failIndex = -4 Or failIndex = -5
                                    unsupportedMessage = "Possibly the feed has no Roku-compatible video content."
                                End If
                            Else
                                failMessage = "Unknown failure code: " + failIndex.ToStr ()
                            End If

                            For i = 0 To contentList [index].Streams.Count () - 1
                                stream = contentList [index].Streams [i]
                                _debug ("uiPlayVideo. Stream[" + i.ToStr () + "]. Url: " + stream.Url)
                            End For

                            uiDisplayMessage ("Video Playback Failed", [failMessage, message, unsupportedMessage])
                        Else
                            _debug ("uiPlayVideo. Retry Attempt #" + numRetries.ToStr ())
                            uiDisplayCanvasMessage ("Video Playback Failed. " + Chr (10) + Chr (10) + "Retrying ....", 3000)
                            done = False
                        End If
                        ui.Close ()
                    End If
                End If
            End While
        End While

    End If

    Return normalCompletion

End Function
Function uiDisplayCanvasMessage (message As String, timeout = 0 As Integer) As Void
    port = CreateObject ("roMessagePort")
    ui = CreateObject ("roImageCanvas")
    ui.SetMessagePort (port)
    ui.SetLayer (0, {Color: "#FF101010"})
    ui.SetLayer (1, {Text: message, TextAttrs:  {Color: "#FFEBEBEB", Font: "Large", HAlign: "HCenter", VAlign: "VCenter"}})
    ui.Show ()
    msg = Wait (timeout, port) : _logEvent ("uiDisplayCanvasMessage", msg)
    ui.Close ()
End Function
Function uiDisplayMessage (title As String, textList As Object) As Void
    port = CreateObject ("roMessagePort")
    ui = CreateObject ("roMessageDialog")
    ui.SetMessagePort (port)
    ui.SetTitle (title)
    For Each textItem In textList
        ui.SetText (textItem)
    End For
    ui.AddButton (1, "OK")
    ui.EnableBackButton (True)
    ui.Show ()
    While True
        msg = Wait (0, port) : _logEvent ("uiDisplayMessage", msg)
        If msg <> Invalid
            If Type (msg) = "roMessageDialogEvent"
                If msg.IsScreenClosed ()
                    Exit While
                Else If msg.IsButtonPressed ()
                    ui.Close ()
                End If
            End If
        End If
    End While
End Function
Function uiSoftError (functionString As String, lineNumber As Integer, errorString As String) As Void
    msg = "Soft error in " + functionString + " on line #" + lineNumber.ToStr ()
    _debug ("uiSoftError. " + msg + ". " + errorString)
    uiDisplayMessage ("Error", [errorString])
End Function
Function uiFatalError (functionString As String, lineNumber As Integer, errorString As String) As Void
    msg = "Fatal error in " + functionString + " on line #" + lineNumber.ToStr ()
    _debug ("uiFatalError. " + msg + ". " + errorString)
    uiDisplayMessage ("Fatal Error", [msg, errorString])
    Stop
End Function

