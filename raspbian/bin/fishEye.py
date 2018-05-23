
#import cv2
from servo import angle
import os
import time

#cap = cv2.VideoCapture(0)
#cap.set(3, 1920)
#cap.set(4, 1080)
#cap.set(6, cv2.VideoWriter.fourcc('M', 'J', 'P', 'G'))


#angle(0, 0)
#_, frame =cap.read()
#cv2.imwrite('photo_0_0.jpg', frame)

#for i in (0, 30):
i=0
for j in (0, 45, 90, 135, 180, -135, -90, -45):
    angle(j, i)
    time.sleep(1)
            #if -90 <= j and j <= 90:
                #	os.system('raspistill -t 1 -vf -hf -o photo_' +str(j) +'_' +str(i) +'.jpg')
                #else:
		#	os.system('raspistill -t 1 -o photo_' +str(j) +'_' +str(i) +'.jpg')


#cap.release()
#cv2.destroyAllWindows()
