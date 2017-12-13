mv_Daily='url1'
mv_Pull='url2'

mv_Daily_size=`wget --no-check-certificate -O - $mv_Daily | grep reports.tar | wc -l`
echo $mv_Daily_size

for i in $(seq 1 ${mv_Daily_size})
do	
	mv_Daily_url=`wget --no-check-certificate -O - $mv_Daily | grep reports.tar | grep -Po 'href="\K.*?(?=")' | head -n ${i} | tail -1`
	echo $mv_Daily_url
	mv_Daily_file=`echo $mv_Daily"/"$mv_Daily_url`
	echo "************"$mv_Daily_file"*************"
	wget --no-check-certificate $mv_Daily_file
	tar -xvf $mv_Daily_url -C Daily
	rm $mv_Daily_url
done

mv_Pull_size=`wget --no-check-certificate -O - $mv_Pull | grep reports.tar | wc -l`
echo $mv_Pull_size

for i in $(seq 1 ${mv_Pull_size})
do
	mv_Pull_url=`wget --no-check-certificate -O - $mv_Pull | grep reports.tar | grep -Po 'href="\K.*?(?=")' | head -n ${i} | tail  -1`
	echo $mv_Pull_url
	mv_Pull_file=`echo $mv_Pull"/"$mv_Pull_url`
	echo "************"$mv_Pull_file"*************"
	wget --no-check-certificate $mv_Pull_file
	tar -xvf $mv_Pull_url -C Pull
	rm $mv_Pull_url
done
