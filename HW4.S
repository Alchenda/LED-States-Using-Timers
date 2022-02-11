    #Danny Webb-McClain
    #Micro 1
    #HW 4
    .text		## Text section contains code
    .set noreorder	## Disable instruction reordering
    .globl main		## Define main label as a global entity
    .ent main		##   and an entry point    

# Including xc.h allows use of SFR names, bit masks, etc.
#include <xc.h>
    
main:
    # Configure I/O ports--LEDs on Port A & C; switches on Port B
    sw	    zero, TRISA		    ## TRISA = 0  --> all PORTA bits = output
    sw	    zero, ANSELA	    ## ANSELA = 0 --> all PORTA bits digital
    not	    t0, zero		    
    sw	    t0, TRISB		    ## TRISB = 0xFFFFFFFF --> all PORTB bits = input
    sw	    zero, ANSELB	    ## ANSELB = 0 --> all PORTB bits digital  
    sw	    zero, TRISC		    ## TRISC = 0  --> all PORTC bits = output
    sw	    zero, ANSELC	    ## ANSELC = 0 --> all PORTC bits digital

    li	    t0, _PORTA_RA0_MASK	    ## t0 = 0x00000001 --> control LED1
    li	    t1, _PORTC_RC9_MASK	    ## t1 = 0x00000200 --> control LED2
    li	    t5, _PORTB_RB7_MASK	    ## t5 = 0x00000080 --> saved state of S1
    li	    t6, _PORTB_RB13_MASK    ## t6 = 0x00002000 --> saved state of S2
    
    li	    s1, 0		    ## Mode indicator for S1
    li	    s2, 0		    ## Mode indicator for S2
## Repeatedly read (poll) switches; turn on LED if button pressed;
## turn off LED if button released 
    
## Start with state of S1
StoreLEDs:
    add	    t5, t3, zero			## Saves state of S1
    add	    t6, t4, zero			## Saves state of S2
    
ReadS1:    
    lw	    t2, PORTB				## Reads Port B
    andi    t3, t2, _PORTB_RB7_MASK		## Checks S1
    andi    t4, t2, _PORTB_RB13_MASK		## Checks S2
    
    bne	    t3, zero, CopyS1			## If button not pressed, save state
    nop
    
    beq	    t3, t5, ReadS2			## If button pressed but not changed,
    nop						## check S2
    
    bne	    t3, t5, S1ModeAdder			## If button is a new press,
    nop						## toggles blinking
    
    jal	    Delay1				## Initiate button delay sequence
    nop
    
    lw	    t2, PORTB
    andi    t3, t2, _PORTB_RB7_MASK
    bne	    t3, zero, CopyS1
    nop
    
    sw	    t0, LATAINV				## If new button press, inverts LED1
    
CopyS1:
    add	    t5, t3, zero			## Saves state of S1
BlinkLEDs:
    bne	    s1, 0, S1Mode			## If S1 button pressed,
    nop						## stop default blinking
    beq	    t4, 0, ReadS2			## (Initial) If S2 button pressed and
    nop						## S1 button not pressed, read S2
    bne	    s2, 0, ReadS2			## (After) If S2 button pressed and
    nop						## S1 button not pressed, read S2
    jal	    DelayBlink				## Jumps to delayBlink counter
    nop
    sw	    t0, LATAINV				## Inverts LED1
    sw	    t1, LATCINV				## Inverts LED2
    j	    ReadS2
    nop
    
S1ModeAdder:
    add	    s1, s1, 1				## If button pressed, increment mode
    
S1Mode:
    beq	    s1, 1, StopBlink			##pause blinking
    nop
    beq	    s1, 2, StartBlink			##resume blinking
    nop
    beq	    s1, 3, ResetInitialS1		## Return initial opcode
    nop
    
ResetInitialS1:
    li	    s1, 1				## Resets S1 mode indicator to 0
    j	    S1Mode
    nop

StopBlink:
    add	    t5, t3, zero			## Saves state of S1
    add	    t6, t4, zero			## Saves state of S2
    j	    ReadS2				## Returns to read S2
    nop
    
StartBlink:
    jal	    DelayBlink				## Jumps to delay counter
    nop
    bne	    s2, 0, ReadS2			## If S2 button pressed,
    nop						## stop default blinking
    sw	    t0, LATAINV				## Inverts LED1
    sw	    t1, LATCINV				## Inverts LED2
    j	    ReadS2				## Returns to read S2
    nop
    
ReadS2:
    andi    t4, t2, _PORTB_RB13_MASK		## Checks S2
    bne	    t4, zero, CopyS2			## If button not pressed, save state
    nop
    beq	    t4, t6, ReadS1			## If button pressed but not changed,
    nop						## check S1
    bne	    t4, t6, S2ModeAdder			## If button is a new press,
    nop						## modes initiate
    jal	    Delay1				## Perform button delay sequence
    nop
    lw	    t2, PORTB
    andi    t4, t2, _PORTB_RB13_MASK
    bne	    t4, zero, CopyS2
    nop
    sw	    t1, LATCINV				## If new button press, inverts LED2
     
CopyS2:
    add	    t6, t4, zero			## Saves state of S2  

JumpDelay:
    jal	    DelayBlink				## Jumps to delay counter
    nop
    beq	    s2, 0, ReadS1			## If button not pressed, read S1
    nop
    j	    S2ModeCheck				## Jumps to S2 mode check
    nop
    
S2ModeAdder:
    add	    s2, s2, 1				## If button pressed, increment mode
    
S2ModeCheck:    #using an opcode to track button to act as a switch
    beq	    s1, 1, ReadS1			## If pause is enabled, read S1
    nop
    beq	    s2, 1, LED1ONLED2OFF		## Enter mode 1, LED1 blinking
    nop						## and LED2 paused
    beq	    s2, 2, LEDTogether			## Enter mode 2, LEDs blinking
    nop						## simultaneously
    beq	    s2, 3, LED2ONLED1OFF		## Enter mode 3, LED2 blinking
    nop						## and LED1 paused
    beq	    s2, 4, LEDAlternating		## Enter mode 4, LEDs alternating
    nop
    beq	    s2, 5, ResetS2Mode			## Resets to enter mode 1
    nop
    
ResetS2Mode:
    li	    s2, 1				## Resets S2 mode indicator to 0
    j	    S2ModeCheck
    nop
    
LED1ONLED2OFF:
    add	    t5, t3, zero			## Saves state of S1
    add	    t6, t4, zero			## Saves state of S2
    sw	    t0, LATAINV				## Inverts LED1
    j	    ReadS1				## Returns to read S2
    nop
    
LEDTogether:
    add	    t5, t3, zero			## Saves state of S1
    add	    t6, t4, zero			## Saves state of S2
    
    sw	    t0, LATASET				## Sets LED1
    sw	    t1, LATCSET				## Sets LED2
    
    jal	    DelayBlink				## Jumps to delay counter
    nop
    
    sw	    t0, LATAINV				## Inverts LED1
    sw	    t1, LATCINV				## Inverts LED2
    
    j	    ReadS1				## Returns to read S2
    nop
    
LED2ONLED1OFF:
    add	    t5, t3, zero			## Saves state of S1
    add	    t6, t4, zero			## Saves state of S2

    sw	    t1, LATCINV				## Inverts LED2
    
    j	    ReadS1				## Returns to read S2
    nop
    
LEDAlternating:    
    sw	    t0, LATASET				## Sets LED1
    sw	    t1, LATCCLR				## Inverts LED2
    
    jal	    DelayBlink				## Jumps to delay counter
    nop
    
    sw	    t0, LATAINV				## Inverts LED1
    sw	    t1, LATCINV
    
    j	    ReadS1
    nop
    
DelayBlink:
    li	    s0, 0x002AAAAA			## Delay counter
    
DelayLoop:
    addi    s0, s0, -1				## Decrements delay counter
    bne	    s0, zero, DelayLoop
    nop
    
    jr	    ra
    nop
    
    .end main 
    .ent Delay1
    
Delay1:
    li	    t7, 0x61A8				## Debounce delay loop to deal with button changes
    
Loop:
    addi    t7, t7, -1
    bne	    t7, zero, Loop
    nop
    
    jr	    ra
    nop

    .end Delay1