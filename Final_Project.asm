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
    currentScore DWORD 0d

    currentX BYTE ?
    currentY BYTE ?

    ; ------------------------
    ; Variables for isGameOver
    ; ------------------------

    isGameOver BYTE 0
    gameOverScreenMsg BYTE "Game Over: Sorry you lose!", 0

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

    call LoadWords
    mov eax, 0

    GameLoop:

    ; ----------------
    ; Check isGameOver
    ; ----------------

    cmp [isGameOver], 0
    jne GameOverScreen

    call Clrscr
    call SetCurrentWord
    call FirstDisplay
    call GetInput
    inc [currentScore]
    jmp Gameloop

    GameOverScreen:

    mov edx, OFFSET gameOverScreenMsg
    call Clrscr
    call WriteString

    ExitGame:
        invoke ExitProcess, 0
main ENDP

.code

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
        promptMessage BYTE "What would you like to do?", 0
        startMessage BYTE "1. Start!", 0
        quitMessage BYTE "2. Quit Game", 0

    .code

        mov edx, OFFSET titleMessage
        call WriteString
        call Crlf
        mov edx, OFFSET promptMessage
        call WriteString
        call Crlf
        call Crlf
        mov edx, OFFSET startMessage
        call WriteString
        call Crlf
        mov edx, OFFSET quitMessage
        call WriteString
        call Crlf

        call ReadChar

    ret
ShowStartMenu ENDP

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
            mov inputChar, al
            mov currentPosition, edi
            call DisplayWord
            inc edi
        loop GetCheckandDisplay

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
                call DisplayScore
                mov dh, [currentY]
                mov dl, [currentX]
                add dl, BYTE PTR [currentPosition]
                call Gotoxy
                mov eax, white + (black * 16)
                call SetTextColor
                mov edx, [currentPosition]
                mov al, BYTE PTR currentWord[edx]
                call WriteChar
                jmp DisplayLoopNext
                
            CheckCorrect:
                mov al, BYTE PTR currentWord[edi]
                cmp al, [inputChar]
                je GreenDisplay

                RedDisplay:
                inc [isGameOver]
                call DisplayScore
                mov dh, [currentY]
                mov dl, [currentX]
                add dl, BYTE PTR [currentPosition]
                call Gotoxy
                mov eax, white + (red * 16)
                call SetTextColor
                mov edx, [currentPosition]
                mov al, BYTE PTR currentWord[edx]
                call WriteChar
                jmp DisplayLoopNext

                GreenDisplay:
                call DisplayScore
                mov dh, [currentY]
                mov dl, [currentX]
                add dl, BYTE PTR [currentPosition]
                call Gotoxy
                mov eax, white + (green * 16)
                call SetTextColor
                mov edx, [currentPosition]
                mov al, BYTE PTR currentWord[edx]
                call WriteChar

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

        ret

SetCurrentWord endp

FirstDisplay proc
    
    .code
    call DisplayScore
    call SetXandY
    mov dh, [currentY]
    mov dl, [currentX]
    call Gotoxy
    mov edx, OFFSET currentWord
    call WriteString

    ret

FirstDisplay endp

SetXandY proc

    call Randomize
    mov eax, 30d
    call RandomRange
    mov [currentX], al

    call Randomize
    mov eax, 30d
    call RandomRange
    mov [currentY], al

ret
SetXandY endp

DisplayScore proc

    .data
    
    topLine BYTE "------", 0
    titleLine BYTE "Score:", 0
    bottomLine BYTE "------", 0

    .code
        
        mov dh, 5d
        mov dl, 35d
        call Gotoxy

        mov eax, white + (black * 16)
        call SetTextColor
        mov edx, OFFSET topLine
        call WriteString
        mov dh, 6d
        mov dl, 35d
        call Gotoxy
        mov edx, OFFSET titleLine
        call WriteString
        mov dh, 7d
        mov dl, 37d
        call Gotoxy
        mov eax, [currentScore]
        call WriteDec
        mov dh, 8d
        mov dl, 35d
        call Gotoxy
        mov edx, OFFSET bottomLine
        call WriteString

ret
DisplayScore endp




end main