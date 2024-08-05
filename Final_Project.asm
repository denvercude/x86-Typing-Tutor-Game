; Final_Project.asm
; Description: Typing Tutor Game
; Author: Denver Cude
; Date: 11/10/23

.386
include Irvine32.inc
.model flat,stdcall
.stack 4096
ExitProcess proto,dwExitCode:dword

.code
main proc

.data
    
   
    ; -------------------------------------------------------------------------
    ; Variables for reading words from text file and taking input from the user
    ; -------------------------------------------------------------------------

    wordArray DWORD 500 DUP(?)
    currentPosition DWORD ?
    currentWord QWORD ?
    inputChar BYTE ?

    ; ------------------------------
    ; Variables for display purposes
    ; ------------------------------

    promptMessage BYTE "What would you like to do?", 0
    windowLine BYTE "------------------------------------------------------------------", 0
    sideWindowLine BYTE "|", 0
    sideLineYValue DWORD ?
    topLine BYTE "------", 0
    bottomLine BYTE "------", 0

    currentX BYTE ?
    currentY BYTE ?

    timeValue DWORD 60d
    decrementTimer DWORD ?
    timeTitleLine BYTE "Time Left:", 0
    timerTopLine BYTE "----------", 0
    timerBottomLine BYTE "----------", 0
    secondsMsg BYTE "seconds", 0

    ; ---------------------------
    ; Variables for score keeping
    ; ---------------------------

    currentScore DWORD 0d
    correctLetter BYTE 0d

    ; ------------------------
    ; Variables for isGameOver
    ; ------------------------

    quitMessage BYTE "2. Quit Game", 0
    isGameOver BYTE 0
    gameOverScreenMsg BYTE "Game Over!", 0
    
    ; -------------------------
    ; Variables for high score.
    ; -------------------------

    highScores DWORD ?


.code
    ; -----------------------
    ; Displays the Start Menu
    ; -----------------------

    call ShowStartMenu

    ; ----------------------------------------------
    ; Checks eax for the value returned by StartMenu
    ; If the value is not 1, the game is exited.
    ; ----------------------------------------------
     
    cmp al, 49
    jne ExitGame

    call LoadHighScores
    call LoadWords
    mov eax, 0

    NewGame:

    call CountDownScreen

    GameLoop:

    ; ----------------
    ; Check isGameOver
    ; ----------------

    cmp [isGameOver], 0
    jne GameOverScreen

    Call Clrscr
    call FrameGameWindow
    call SetCurrentWord
    cmp [correctLetter], 7
    jl NoScore
    inc[currentScore]
    NoScore:
    mov [correctLetter], 0
    call DisplayScore
    call FirstDisplay
    call GetInput
    jmp Gameloop

    GameOverScreen:
    call DisplayGameOver
    call ReadChar

    ; ----------------------------
    ; Check to Display High Scores
    ; ----------------------------
    
    cmp al, 50
    je HighScoreDisplay

    ; --------------------
    ; Check to Start Again
    ; --------------------
    cmp al, 49
    je PlayAgain

    cmp al, 51
    je ExitGame

    jmp GameOverScreen

    PlayAgain:
    mov eax, 0
    mov currentScore, eax
    mov [correctLetter], 0
    mov [isGameOver], al
    mov [timeValue], 120d
    jmp NewGame

    HighScoreDisplay:
    call DisplayHighScores

    ExitGame:
        call Clrscr
        invoke ExitProcess, 0

main ENDP

ShowStartMenu PROC

; --------------------------------------------------------------------------------------
; ShowStartMenu: Displays the start menu. Gives the user the option to 1. Start Game or
;                2. Quit Game. If the user enters 1, the subroutine return control to 
;                the main proc, which begins the game loop. If the user enter 0, the
;                subroutine returns control to the main proc, which invokes the exit
;                process.
; --------------------------------------------------------------------------------------
    
    .data

        titleMessage BYTE "Word Popcorn: A Typing Tutor Game", 0
        startMessage BYTE "1. Start!", 0

    .code

        ; --------------------------
        ; Display start menu options
        ; --------------------------

        mov dh, 10
        mov dl, 18
        call Gotoxy
        mov edx, OFFSET titleMessage
        call WriteString
        
        mov dh, 12
        mov dl, 22
        call Gotoxy
        mov edx, OFFSET promptMessage
        call WriteString
        
        mov dh, 14
        mov dl, 26
        call Gotoxy
        mov edx, OFFSET startMessage
        call WriteString

        mov dh, 15
        mov dl, 26
        call Gotoxy
        mov edx, OFFSET quitMessage
        call WriteString
        
        ; --------------------------
        ; Display framed game window
        ; --------------------------

        call FrameGameWindow

        ; ---------------------------
        ; Reset to default text color
        ; ---------------------------

        mov eax, white + (black * 16)
        call SetTextColor

        ; ---------------------
        ; Read the user's input
        ; ---------------------

        call ReadChar

    ret
ShowStartMenu ENDP

LoadHighScores proc

; --------------------------------------------------------------------------------------------
; LoadHighScores: Reads all names and scores in the HighScoreList.txt file into highScoreNames
; --------------------------------------------------------------------------------------------

    .data
        fileName2 BYTE "HighScoreList.txt"
        fileHandle2 DWORD ?
        bufferSize2 EQU 250
        buffer2 BYTE bufferSize2 DUP (?)
        fileErrorMessage2 BYTE "There was an error opening the file.", 0

    .code
        push eax

        mov edx, OFFSET fileName2
        call OpenInputFile
        mov fileHandle2, eax
        
        cmp eax, INVALID_HANDLE_VALUE
        je FileError2

        mov edx, OFFSET buffer2
        mov ecx, bufferSize2
        call ReadFromFile
        
        mov esi, 0
        mov edi, 0
        xor ecx, ecx

        ParseLoop2:
            mov al, buffer2[esi]
            test al, al
            jz Finished2

            cmp al, ' '
            je SkipSpace

            test ecx, ecx
            jnz NextChar2
            mov byte ptr highScores[edi], al
            inc edi
            inc ecx
            jmp ParseLoop2

        NextChar2:
            xor ecx, ecx
            inc esi
            jmp ParseLoop2

        SkipSpace:
            xor ecx, ecx
            mov highScores[esi], 00h
            inc esi
            inc edi
            jmp ParseLoop2

        FileError2:
            mov edx, OFFSET fileErrorMessage
            call WriteString
            pop eax
            ret

        Finished2:
            mov eax, fileHandle2
            call CloseFile
            pop eax
            
            ret

LoadHighScores endp

LoadWords proc

; ------------------------------------------------------------------
; LoadWords: Reads all words in the WordList.txt file into wordArray
; ------------------------------------------------------------------

    .data
        fileName BYTE "WordList.txt"
        fileHandle DWORD ?
        bufferSize EQU 2100
        buffer BYTE bufferSize DUP (?)
        fileErrorMessage BYTE "There was an error opening the file.", 0

    .code
        push eax

        mov edx, OFFSET fileName
        call OpenInputFile
        mov fileHandle, eax
        
        cmp eax, INVALID_HANDLE_VALUE
        je FileError

        mov edx, OFFSET buffer
        mov ecx, bufferSize
        call ReadFromFile
        
        mov esi, 0
        mov edi, 0
        xor ecx, ecx

        ParseLoop:
            mov al, buffer[esi]
            test al, al
            jz Finished

            cmp al, ' '
            je SkipSpace

            test ecx, ecx
            jnz NextChar
            mov byte ptr wordArray[edi], al
            inc edi
            inc ecx
            jmp ParseLoop

        NextChar:
            xor ecx, ecx
            inc esi
            jmp ParseLoop

        SkipSpace:
            xor ecx, ecx
            mov wordArray[esi], 00h
            inc esi
            inc edi
            jmp ParseLoop

        FileError:
            mov edx, OFFSET fileErrorMessage
            call WriteString
            pop eax
            ret

        Finished:
            mov eax, fileHandle
            call CloseFile
            pop eax
            ret

LoadWords endp

GetInput proc

    .code
        
        mov ecx, 7
        mov edi, 0
        GetCheckandDisplay:
            call ReadChar
            cmp [timeValue], 0
            jg NoGameOver
            inc [isGameOver]
            NoGameOver:
            cmp al, 08h
            je BackSpaceHandling
            mov inputChar, al
            mov currentPosition, edi
            cmp [currentPosition], 6
            je LastRedUnderline
            call EraseWriteUnderlines
            LastRedUnderline:
            call DisplayTime
            call DisplayWord
            inc edi
            loop GetCheckandDisplay

        cmp ecx, 0
        je ExitGetInput

        BackSpaceHandling:
            cmp edi, 0
            je GetCheckandDisplay
            mov ebx, edi
            mov dh, [currentY]
            add dh, 1
            mov dl, [currentX]
            add dl, bl
            call Gotoxy
            mov al, ' '
            call WriteChar
            sub dl, 1
            call Gotoxy
            mov eax, red + (black * 16)
            call SetTextColor
            mov al, '_'
            call WriteChar
            mov dh, 0
            mov dl, 0
            Call Gotoxy
            inc ecx
            dec edi
            jmp GetCheckandDisplay

        ExitGetInput:

        ret

GetInput endp

DisplayWord proc

    .code

       DisplayLoop:
            cmp [currentPosition], 7
            jg ExitLoop

            cmp edi, [currentPosition]
            je CheckCorrect

            RegularDisplay:
                mov dh, [currentY]
                mov dl, [currentX]
                add dl, BYTE PTR [currentPosition]
                call Gotoxy
                mov eax, white + (black * 16)
                call SetTextColor
                mov edx, [currentPosition]
                mov al, BYTE PTR currentWord[edx]
                call WriteChar
                mov dh, 0
                mov dl, 0
                Call Gotoxy
                jmp DisplayLoopNext
                
            CheckCorrect:
                mov al, BYTE PTR currentWord[edi]
                cmp al, [inputChar]
                je GreenDisplay

                RedDisplay:
                mov dh, [currentY]
                mov dl, [currentX]
                add dl, BYTE PTR [currentPosition]
                call Gotoxy
                mov eax, white + (red * 16)
                call SetTextColor
                mov edx, [currentPosition]
                mov al, BYTE PTR currentWord[edx]
                call WriteChar
                cmp [currentPosition], 6
                jne DontPause1
                mov dh, 0
                mov dl, 0
                Call Gotoxy
                mov eax, 500d
                call Delay
                DontPause1:
                mov dh, 0
                mov dl, 0
                Call Gotoxy
                jmp DisplayLoopNext

                GreenDisplay:
                inc [correctLetter]
                mov dh, [currentY]
                mov dl, [currentX]
                add dl, BYTE PTR [currentPosition]
                call Gotoxy
                mov eax, white + (green * 16)
                call SetTextColor
                mov edx, [currentPosition]
                mov al, BYTE PTR currentWord[edx]
                call WriteChar
                cmp [currentPosition], 6
                jne DontPause2
                mov dh, 0
                mov dl, 0
                Call Gotoxy
                mov eax, 500d
                call Delay
                DontPause2:
                mov dh, 0
                mov dl, 0
                Call Gotoxy

            DisplayLoopNext:
                inc [currentPosition]
                jmp DisplayLoop


       ExitLoop:

        ret

DisplayWord endp

SetCurrentWord proc

    .code
        call Randomize
        mov eax, 250d
        call RandomRange

        imul eax, eax, 8

        mov edx, wordArray[eax]
        mov DWORD PTR currentWord, edx
        mov edx, wordArray[eax + 4]
        mov DWORD PTR currentWord[4], edx

        call SetXandY

        ret

SetCurrentWord endp

FirstDisplay proc
    
        .code
        push ecx

        ; ---------------------
        ; First display of time
        ; ---------------------

        call GetMseconds
        xor edx, edx
        mov ecx, 1000d
        div ecx

        mov [decrementTimer], eax

        mov dh, 1d
        mov dl, 27d
        call Gotoxy

        mov eax, white + (black * 16)
        call SetTextColor
        mov edx, OFFSET timerTopLine
        call WriteString
        mov dh, 2d
        mov dl, 27d
        call Gotoxy
        mov edx, OFFSET timeTitleLine
        call WriteString
        mov dh, 3d
        mov dl, 30d
        call Gotoxy
        mov eax, [timeValue]
        call WriteDec
        mov dh, 4d
        mov dl, 28d
        call Gotoxy
        mov edx, OFFSET secondsMsg
        call Writestring
        mov dh, 5d
        mov dl, 27d
        call Gotoxy
        mov edx, OFFSET timerBottomLine
        call WriteString

        ; ---------------------
        ; First display of word
        ; ---------------------

        mov dh, [currentY]
        mov dl, [currentX]
        call Gotoxy
        mov edx, OFFSET currentWord
        call WriteString

        ; --------------------------
        ; First display of underline
        ; --------------------------

            mov dh, [currentY]
            add dh, 1
            mov dl, [currentX]
            call Gotoxy
            mov eax, red + (black * 16)
            call SetTextColor
            mov al, '_'
            call WriteChar

            mov dh, 0
            mov dl, 0
            Call Gotoxy

        pop ecx

        ret

FirstDisplay endp

SetXandY proc

    call Randomize
    mov eax, 57d
    call RandomRange
    add al, 2
    mov [currentX], al

    call Randomize
    mov eax, 14d
    call RandomRange
    add al, 6
    mov [currentY], al

ret
SetXandY endp

DisplayScore proc

    .data
    
    titleLine BYTE "Score:", 0

    .code

        mov dh, 21d
        mov dl, 29d
        call Gotoxy

        mov eax, white + (black * 16)
        call SetTextColor
        mov edx, OFFSET topLine
        call WriteString
        mov dh, 22d
        mov dl, 29d
        call Gotoxy
        mov edx, OFFSET titleLine
        call WriteString
        mov dh, 23d
        mov dl, 31d
        call Gotoxy
        mov eax, [currentScore]
        call WriteDec
        mov dh, 24d
        mov dl, 29d
        call Gotoxy
        mov edx, OFFSET bottomLine
        call WriteString

        mov dh, [currentY]
        mov dl, [currentX]
        call Gotoxy

ret
DisplayScore endp

FrameGameWindow proc
    
    .data

    .code
        
        ; ---------
        ; Set Color
        ; ---------

        mov eax, red + (black * 16)
        call SetTextColor
        
        ; --------------------
        ; Display top red line
        ; --------------------

        mov dh, 0
        mov dl, 1
        call Gotoxy
        mov edx, OFFSET windowLine
        call WriteString

        ; -----------------------
        ; Display bottom red line
        ; -----------------------

        mov dh, 25
        mov dl, 1
        call Gotoxy
        mov edx, OFFSET windowLine
        call WriteString

        ; -----------------|
        ; Display left line
        ; -----------------

        mov ecx, 24

        LeftLineLoop1:
        mov sideLineYValue, ecx
        mov dh, BYTE PTR [sideLineYValue] 
        mov dl, 0
        call Gotoxy
        mov edx, OFFSET sideWindowLine
        call writeString
        loop LeftLineLoop1

        ; ------------------
        ; Display right line
        ; ------------------

        mov ecx, 24

        RightLineLoop1:
        mov sideLineYValue, ecx
        mov dh, BYTE PTR [sideLineYValue] 
        mov dl, 67
        call Gotoxy
        mov edx, OFFSET sideWindowLine
        call writeString
        loop RightLineLoop1

        mov dh, 0
        mov dl, 0
        Call Gotoxy

        ; ----------------
        ; Reset text color
        ; ----------------

        mov eax, white + (black * 16)
        call SetTextColor

        ret

FrameGameWindow endp

DisplayGameOver proc
    
    .data
        
        playAgainMsg BYTE "1. Play Again", 0
        scoreMsg BYTE "Score: ", 0
        wpmMsg BYTE "WPM: ", 0
        highscoreOption BYTE "2. Display High Scores", 0
        quitMsg2 BYTE "3. Quit Game", 0

    .code

        call Clrscr

        ; -------------------------
        ; Display the redline frame
        ; -------------------------

        call FrameGameWindow

        ; -------------------------
        ; Display Game Over Options
        ; -------------------------

        mov dh, 7
        mov dl, 28
        call Gotoxy
        mov edx, OFFSET gameOverScreenMsg
        call WriteString

        mov dh, 9
        mov dl, 30
        call Gotoxy
        mov edx, OFFSET scoreMsg
        call WriteString
        mov eax, [currentScore]
        call WriteDec

        mov dh, 11
        mov dl, 30
        call Gotoxy
        mov edx, OFFSET wpmMsg
        call WriteString
        push edx
        mov eax, [currentScore]
        xor edx, edx
        mov ebx, 2
        div ebx
        pop edx
        call WriteDec

        mov dh, 13
        mov dl, 20
        call Gotoxy
        mov edx, OFFSET promptMessage
        call WriteString

        mov dh, 15
        mov dl, 26
        call Gotoxy
        mov edx, OFFSET playAgainMsg
        call WriteString

        mov dh, 16
        mov dl, 26
        call Gotoxy
        mov edx, OFFSET highScoreOption
        call WriteString

        mov dh, 17
        mov dl, 26
        call Gotoxy
        mov edx, OFFSET quitMsg2
        call WriteString
        mov dh, 0
        mov dl, 0
        call Gotoxy

        ret

DisplayGameOver endp

DisplayTime proc

    .code

        push ecx

        ; ------------------
        ; Update Time Values
        ; ------------------

        call GetMSeconds
        xor edx, edx
        mov ecx, 1000d
        div ecx
        sub eax, [decrementTimer]
        sub [timeValue], eax
        call GetMSeconds
        xor edx, edx
        mov ecx, 1000d
        div ecx
        mov [decrementTimer], eax

        ; ------------------
        ; Display Time Value
        ; ------------------

        mov dh, 1d
        mov dl, 27d
        call Gotoxy

        mov eax, white + (black * 16)
        call SetTextColor
        mov edx, OFFSET timerTopLine
        call WriteString
        mov dh, 2d
        mov dl, 27d
        call Gotoxy
        mov edx, OFFSET timeTitleLine
        call WriteString
        mov dh, 3d
        mov dl, 30d
        call Gotoxy
        mov eax, [timeValue]
        call WriteDec
        mov dh, 4d
        mov dl, 28d
        call Gotoxy
        mov edx, OFFSET secondsMsg
        call Writestring
        mov dh, 5d
        mov dl, 27d
        call Gotoxy
        mov edx, OFFSET timerBottomLine
        call WriteString
        
        pop ecx

        ret

DisplayTime endp

EraseWriteUnderlines proc
    
    .code
        
            ; -------------------------
            ; Erase underlined letter
            ; -------------------------
            
            mov ebx, edi
            cmp ebx, 0
            je EraseAtZero

            NotZeroLoop:
            cmp ebx, 0
            jl ContinueDisplayLoop
            mov dh, [currentY]
            add dh, 1
            mov dl, [currentX]
            add dl, bl
            call Gotoxy
            mov al, ' '
            call WriteChar
            dec ebx
            jmp NotZeroLoop

            EraseAtZero:
            mov dh, [currentY]
            add dh, 1
            mov dl, [currentX]
            add dl, BYTE PTR [currentPosition]
            call Gotoxy
            mov al, ' '
            call WriteChar

            ContinueDisplayloop:
            ; -------------------
            ; Write new underline
            ; -------------------

            mov dh, [currentY]
            add dh, 1
            mov dl, [currentX]
            add dl, BYTE PTR [currentPosition]
            add dl, 1
            call Gotoxy
            mov eax, red + (black * 16)
            call SetTextColor
            mov al, '_'
            call WriteChar

            ret

EraseWriteUnderlines endp

DisplayHighScores proc

    .data
    highScoreNames DWORD 3
    highScoreNumbers DWORD 3
    name1 QWORD ?
    number1 WORD ?
    msg1 BYTE "1. ", 0
    msg2 BYTE "2. ", 0
    msg3 BYTE "3. ", 0
    hyphen BYTE "-", 0

    .code
        
        call Clrscr
        call FrameGameWindow

        ; ----------
        ; Load names
        ; ----------

        mov eax, 0
        mov ebx, 0

        LoadNamesLoop:
        cmp eax, 33
        ja ExitLoadNamesLoop

        mov edx, dword ptr highScores[eax]
        mov highScoreNames[ebx], edx
        add eax, 4
        mov edx, dword ptr highScores[eax]
        add ebx, 4
        mov highScoreNames[ebx], edx
        add ebx, 4
        add eax, 7
        jmp LoadNamesLoop

        ExitLoadNamesLoop:

        mov ecx, 3

        ; -----------
        ; Load Scores
        ; -----------

        mov eax, 8
        mov ebx, 0

        LoadScoresLoop:
        mov ax, word ptr highScores[eax]
        mov dword ptr highScoreNumbers[ebx], eax
        add eax, 11
        add ebx, 2
        loop LoadScoresLoop

        ; -------------------
        ; Display High Scores
        ; -------------------

        mov dh, 7
        mov dl, 30
        call Gotoxy
        mov edx, OFFSET msg1
        call WriteString
        mov eax, dword ptr highScoreNames[0]
        mov dword ptr name1[0], eax
        mov eax, dword ptr highScoreNames[4]
        mov dword ptr name1[4], eax
        mov dh, 7
        mov dl, 33
        call Gotoxy
        mov edx, OFFSET name1
        call WriteString
        mov edx, OFFSET name1[4]
        call WriteString
        mov dh, 7
        mov dl, 41
        call Gotoxy
        mov edx, OFFSET hyphen
        call WriteString
        mov eax, highScoreNumbers[0]
        mov number1, ax
        mov dh, 7
        mov dl, 43
        call Gotoxy
        mov edx, OFFSET number1
        call WriteString

        ret

DisplayHighScores endp

CountDownScreen proc
    
    .data
    
    gameInstructions byte "Type as many words as you can in 2 minutes.", 0
    readyMsg byte "Ready?", 0
    countdown3 byte "3", 0
    countdown2 byte "2", 0
    countdown1 byte "1", 0
    countdownGo byte "Go!", 0


    
    .code

        call Clrscr
        call FrameGameWindow
        
        mov dh, 7
        mov dl, 11
        call Gotoxy
        mov edx, OFFSET gameInstructions
        call WriteString
        mov dh, 0
        mov dl, 0
        call Gotoxy

        mov eax, 2000
        call Delay
        call Clrscr
        call FrameGameWindow

        mov dh, 7
        mov dl, 30
        call Gotoxy
        mov edx, OFFSET readyMsg
        call WriteString
        mov dh, 0
        mov dl, 0
        call Gotoxy

        mov eax, 2000
        call Delay
        call Clrscr
        call FrameGameWindow

        mov dh, 7
        mov dl, 32
        call Gotoxy
        mov edx, OFFSET countdown3
        call WriteString
        mov dh, 0
        mov dl, 0
        call Gotoxy

        mov eax, 1000
        call Delay
        call Clrscr
        call FrameGameWindow

        mov dh, 7
        mov dl, 32
        call Gotoxy
        mov edx, OFFSET countdown2
        call WriteString
        mov dh, 0
        mov dl, 0
        call Gotoxy

        mov eax, 1000
        call Delay
        call Clrscr
        call FrameGameWindow

        mov dh, 7
        mov dl, 32
        call Gotoxy
        mov edx, OFFSET countdown1
        call WriteString
        mov dh, 0
        mov dl, 0
        call Gotoxy

        mov eax, 1000
        call Delay
        call Clrscr
        call FrameGameWindow

        mov dh, 7
        mov dl, 32
        call Gotoxy
        mov edx, OFFSET countdownGo
        call WriteString
        mov dh, 0
        mov dl, 0
        call Gotoxy

        mov eax, 1000
        call Delay

        ret
CountDownScreen endp

end main