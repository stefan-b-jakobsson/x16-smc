.equ PAGE_SIZE      = 64    ; In bytes

;******************************************************************************
; Data segment
;******************************************************************************
.dseg

flash_buf:          .byte PAGE_SIZE
flash_zp_buf:       .byte PAGE_SIZE

flash_bufindex:     .byte 1
flash_packetsize:   .byte 1
flash_targetaddr:   .byte 2
flash_checksum:     .byte 1

;******************************************************************************
; Program segment
;******************************************************************************
.cseg

;******************************************************************************
; Function...: flash_backup_zeropage
; Description: Backups flash memory zero page (64 bytes) to the RAM buffer
;              flash_zp_buf
; In.........: YL:YH Pointer to RAM buffer where backup is stored
; Out........: Nothing
; Affects....: r16, r17, Y, Z
flash_backup_zeropage:
    ldi r16,PAGE_SIZE               ; Init counter
    
    clr ZL                          ; Z = Flash memory address 0x0000
    clr ZH

flash_backup_zeropage_loop:
    lpm r17,Z+                      ; Read one byte, increase Z
    st Y+,r17                       ; Store byte in buffer, increase Y
    subi r16,1                      ; Decrease counter
    brne flash_backup_zeropage_loop ; Check if we're done
    ret

;******************************************************************************
; Function...: flash_write_buf
; Description: Writes flash_buf (64 bytes) to flash memory
; In.........: ZL:ZH Flash memory target address (in bytes, not words)
; Out........: Nothing
; Affects....: r16, r17, r19, Y, Z
flash_write_buf:
    ldi YL,low(flash_buf)           ; Y = RAM buffer pointer
    ldi YH,high(flash_buf)
    ; Fallthrough to flash_write

;******************************************************************************
; Function...: flash_write
; Description: Writes one page (64 bytes) to flash memory
; In.........: YL:YH Pointer to RAM buffer holding values to be written
;              ZL:ZH Flash memory target address (in bytes, not words)
; Out........: Nothing
; Affects....: r16, r17, r19, Y, Z
flash_write:
    ; Erase page
    ldi r17, (1<<PGERS) + (1<<SPMEN)
    rcall flash_spm                 ; Perform erase
    
    ; Copy data from RAM buffer pointed to by Y into SPM temp buffer
    ldi r16, PAGE_SIZE              ; Init counter
flash_write_loop:
    ld r0, Y+                       ; Copy one word from buffer into r0:r1
    ld r1, Y+
    ldi r17, (1<<SPMEN)
    rcall flash_spm                 ; Perform copy
  
    subi ZL,-2                      ; Z = Z - (-2) => Z = Z + 2
    subi r16,2                      ; counter = counter - 2
    brne flash_write_loop           ; Check if we're done
 
    ; Write page
    subi ZL,PAGE_SIZE               ; Restore flash memory address to its start value
    ldi r17, (1<<PGWRT) + (1<<SPMEN)
    rjmp flash_spm                 ; Perform write

;******************************************************************************
; Function...: flash_spm
; Description: Performs Store Program Meomory operation
; In.........: r17 Value to be written to SPMCSR before operation, selecting
;                  SPM command
; Out........: Nothing
; Affects....: r19
flash_spm:
    in r19, SPMCSR                  ; Wait for SPM not busy (SPMEN=0)
    sbrc r19, SPMEN
    rjmp flash_spm

    out SPMCSR, r17                 ; Perform SPM
    spm

    ret

;******************************************************************************
; Function...: flash_targetaddr_in_zp
; Description: Checks if flash_targetaddr is in zero page, i.e. the first 64
;              bytes
; In.........: Nothing
; Out........: Carry bit, 0=in zp, 1=not in zp
flash_targetaddr_in_zp:
    ; Let's do a 16 bit comparison: flash_targetaddr - 0x0040
    lds r17,flash_targetaddr
    cpi r17,0x40                    ; Compare low 8 bits: addrL - 0x40 => CL=0 else CL=1

    clr r17                         
    lds r18,flash_targetaddr+1
    cpc r18,r17                     ; Compare high 8 bits, taking into account carry from first operation

    ret