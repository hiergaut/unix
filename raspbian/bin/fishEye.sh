#! /bin/bash -e


for j in 0 45 90 135 180 -135 -90 -45; do
	python servo.py -m $j 0

	if [ $j -ge -90 -a $j -le 90 ]; then
		raspistill -t 100 -vf -hf -o photo_"$j"_0.jpg
	else
		raspistill -t 100 -o photo_"$j"_0.jpg
	fi
done

	#    if -90 <= j and j <= 90:
	#        os.system('raspistill -t 100 -vf -hf -o photo_' +str(j) +'_' +str(i) +'.jpg')
	#    else:
#        os.system('raspistill -t 100 -o photo_' +str(j) +'_' +str(i) +'.jpg')


#cap.release()
#cv2.destroyAllWindows()
