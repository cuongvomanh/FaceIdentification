#!/bin/bash

check_file() 
{
	if [ ! -f "$1" ]
	then
		return 0
	else
		return 1
	fi
}

check_dir() 
{
	if [ ! -d "$1" ]
	then
		return 0
	else
		return 1
	fi
}

# Check if data dir exists
check_dir $origin_data_dir
retval=$?
if [ $retval -eq 0 ]
then
	echo "Data directory ($origin_data_dir) does not exist"
	exit 1
fi


# Check # of arguments
usage() {
	echo ""
	echo " Usage:"
	echo ""
	echo "   bash $0 -d data/data_directory:"
	echo ""
	echo "   -d   Data dir path (example: ../data/vn_celeb_face_recognition)"
	echo "   -h   Print this help information"
	echo ""
	exit 1
}

while getopts 'd:h' OPTION; do
	case $OPTION in
		d) origin_data_dir=$OPTARG;;
		h) usage;;
	esac
done

if [ -z "$origin_data_dir"  ]; then echo "Data dir not set."; usage; exit 1; fi


export PYTHONPATH=$PYTHONPATH:src/common
export PYTHONPATH=$PYTHONPATH:src/eval

# Check if train dir exists, if not, create it
check_dir ../data/convert/train
retval=$?
if [ $retval -eq 1 ]
then
	rm -rf ../data/convert/train
fi
mkdir -p ../data/convert/train

# Check if test dir exists, if not, create it
check_dir ../data/convert/test
retval=$?
if [ $retval -eq 1 ]
then
	rm -rf ../data/convert/test
fi
mkdir -p ../data/convert/test

# Check if train vector dir exists, if not, create it
check_dir ../models/vector/
retval=$?
if [ $retval -eq 1 ]
then
	rm -rf ../models/vector/
fi
mkdir -p ../models/vector/

# Check if test vector dir exists, if not, create it
check_dir ../models/vector_test/
retval=$?
if [ $retval -eq 1 ]
then
	rm -rf ../models/vector_test/
fi
mkdir -p ../models/vector_test/

# Check if output dir exists, if not, create it
check_dir ../output
retval=$?
if [ $retval -eq 1 ]
then
	rm -rf ../output
fi
mkdir -p ../output


python ../aivivn/change_structure.py --indir=../data/vn_celeb_face_recognition/train --des_file_path=../data/vn_celeb_face_recognition/train.csv --outdir=../data/convert/train
python ../aivivn/change_structure.py --indir=../data/vn_celeb_face_recognition/test --oneperperson=True --outdir=../data/convert/test


python ../aivivn/process_lfw.py --indir=../data/convert/train --outdir=../data/convert/train --npair=40000

python ../aivivn/train.py --data-dir=../data/convert/train --model-path=../models/model.pkl --idx2path=../models/idx2path.pkl --vector-dir=../models/vector/

python ../aivivn/view_data.py --data-dir=../data/convert/train --vector-dir=../models/vector/ --threshold=1.24 --output-path=../output/data_view.txt

python ../aivivn/vertification_by_embedding.py --data-dir=../data/convert/train --known-vector-dir=../models/vector/ --threshold-range=0.5,2,0.01

for t in  1.30 1.35 1.40 1.45 1.50 1.55 1.60;do python ../aivivn/aivivn_vertification.py --data-dir=../data/convert/test --model-path=../models/model.pkl --idx2path=../models/idx2path.pkl --known-vector-dir=../models/vector/ --ver-vector-dir=../models/vector_test/ --threshold=$t --k=5  --batch-size=1000 --tree-path=../models/tree.pkl --output=../output/${t//['.']/''}.csv; done 

for f in ../output/*.csv;do a=${f//[.csv]/};python ../add_code/review_result.py --input_path=$f --output_path=$a.jpg;done