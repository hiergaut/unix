
import RPi.GPIO as GPIO
import time
import sys
import curses
import datetime

#gpio pin of horizontal rotation servo 0..90 degree
hPin=23 

#gpio pin of vertical rotation servo -90..90 degree
vPin=18 


#init gpio in output mode
GPIO.setwarnings(False)
GPIO.setmode(GPIO.BCM)
GPIO.setup(hPin, GPIO.OUT)
GPIO.setup(vPin, GPIO.OUT)

#init pwm, all gpio are pwm abilities
#frequence of pwm
f=100


def findMechanicalStop():
    middle=10

    hPwm =GPIO.PWM(hPin, f)
    vPwm =GPIO.PWM(vPin, f)
#    stop=False
#    while (not stop):
#        pos -=1
#        hPwm.start(pos)
#
#        #ret =ord(raw_input("space to continue, enter to confirm abut: "))
#        ret =ord(sys.stdin.read(1))
#        print(ret)

    #non-blocking get input
    stdscr = curses.initscr()
    curses.noecho()
    stdscr.nodelay(1) # set getch() non-blocking

    stdscr.addstr(0,0,"Press \"ENTER to confirm abut, space to jump")
    line = 1

    toes =["vMin", "vMax", "hMin", "hMax"]
    pwms =[vPwm, vPwm, hPwm, hPwm]
    values =[0, 0, 0, 0]
    sens =[-1, 1, -1, 1]
    for i in range(4):
        pos=middle

        try:
            while (1):
                c = stdscr.getch()
                if c == 10: 
                    values[i] =round(pos, 2)
                    break
                elif c == 32:
                    print("space")
                    pos =pos +sens[i] *5
                else:
                    pos =pos +sens[i] *0.1

                stdscr.addstr(line, 0, "actual pos "+ str(pos))
                pwms[i].start(pos)

                time.sleep(0.1)


        finally:
            curses.endwin()

    for i in range(4):
        print(toes[i], " =", str(values[i]))




def angle(vAngle, hAngle):
    vMin=4.0
    vMax=25.0

    hMin=3.7
    hMax=50.0




    hPwm =GPIO.PWM(hPin, f)
    vPwm =GPIO.PWM(vPin, f)


    assert (-180 <= vAngle and vAngle <= 180)
    assert (0 <= hAngle and hAngle <= 90)


    if -90 <= vAngle and vAngle <=  90:
        vPwm.start(vMax -(vAngle +90) *(vMax -vMin) /180.0)
        hPwm.start(hAngle *hMax /180.0 +hMin)

    elif vAngle < -90:
        vPwm.start(vMin +(-vAngle -90) *(vMax -vMin) /180.0)
        hPwm.start(hMax -hAngle *(hMax -hMin) /180.0)

    else:
        vPwm.start(vMax -(vAngle -90) *(vMax -vMin) /180.0)
        hPwm.start(hMax -hAngle *(hMax -hMin) /180.0)

    time.sleep(1)
    hPwm.stop()
    vPwm.stop()



# ==1 for external lib import
if len(sys.argv) != 1:


    # args =vars(parser.parse_args())
    p =sys.argv[1]
    if (p =="-h"):
        print("\
usage: servo [option]\n\
option:\n\
    -h  print this help message\n\
    -i  init mechanical stop\n\
    -m  move to specific angle, first vertical rotation (-90..90), second horizontal rotation (0..90)\n\
example:\n\
    python servo.py -m 0 0\n\
        to move servo straight")
    elif (p =="-i"):
        findMechanicalStop()
    elif (p =="-m"):
        if len(sys.argv) != 4:
            print("servo -m <-90..90 degree of vertical rotation> <0..90 degree of horizontal rotation>")
        else:
            angle(int(sys.argv[2]), int(sys.argv[3]))
    else:
        print("option not found")


