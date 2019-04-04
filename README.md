# Face Identification using ArcFace in vn_celeb_face_recognition dataset 

----
## Yêu cầu, setup môi trường và download pretrained model

1. Yêu cầu

```
sudo apt install wget unzip virtualenv
```

2. Setup môi trường

Mình giả định rẳng bạn đang ở folder *`$FaceIdentification_ROOT`*

```
. ./setup
```

3. Download pretrained model

Mình giả định rằng bạn đang ở folder *`$INSIGHTFACE_ROOT`*

```
bash ../download_model.sh
```
----
## Các bước chạy trong project

Từ đây mình luôn giả định rằng bạn đang ở folder *`$INSIGHTFACE_ROOT`*

1. Đưa dữ liệu về train và test về dạng datasets giống với lfw dataset.


```
python ../aivivn/change_structure.py --indir=../data/vn_celeb_face_recognition/train --des_file_path=../data/vn_celeb_face_recognition/train.csv --outdir=../data/convert/train
```
```
python ../aivivn/change_structure.py --indir=../data/vn_celeb_face_recognition/test --oneperperson=True --outdir=../data/convert/test
```

2. Sử dụng SVM train một bộ classification 1000 lớp.

```
python ../aivivn/train.py --data-dir=../data/convert/train --model-path=../models/model.pkl --idx2path=../models/idx2path.pkl --vector-dir=../models/vector/
```

3. Tìm ra threshold để xác định hai mặt là của cùng một người hay thuộc hai người khác nhau trên bộ dữ liệu train.

Vì ta không biết được tỉ lệ người lạ, người quen trong bộ dữ liệu test nên ta sẽ xem độ quan trọng của xác nhận người quen và phát hiện người là ngang nhau. Ta lấy ra từ bộ dữ liệu train 40000 cặp ảnh, trong đó 20000 cặp ảnh có hai ảnh là thuộc cùng một người và 20000 cặp ảnh có hai ảnh là thuộc hai người khác nhau để đánh giá độ chính xác.

```
python ../aivivn/process_lfw.py --indir=../data/convert/train --outdir=../data/convert/train --npair=40000
```
Từ 40000 cặp ảnh này, ta sẽ tìm được threshold có độ chính xác lớn nhất, miền threshold tìm kiếm là từ 0.5 đến 2 (có thể tìm kiếm ở miền lớn hơn).

```
python ../aivivn/vertification_by_embedding.py --data-dir=../data/convert/train --known-vector-dir=../models/vector/ --threshold-range=0.5,2,0.01
```
Ta tìm được threshold tốt nhất là 1.46 với độ chính xác trên 97% trên bộ train.

4. Xem dữ liệu và đề xuất những ảnh bị gán nhãn sai (những ảnh có khoảng cách giữa ảnh đấy và những ảnh còn lại thuộc cùng một người lớn hơn một threshold)

```
python ../aivivn/view_data.py --data-dir=../data/convert/train --vector-dir=../models/vector/ --threshold=1.24 --output-path=../output/data_view.png
```
Số ảnh của từng người trong bộ dữ liệu train:
![image number per person](https://github.com/cuongvomanh/FaceIdentification/tree/master/resources/file_number2n.png)

Sau đó dựa vào những đề xuất này, ta tiến hành lọc bỏ những ảnh nhiễu trong dữ liệu train (khoảng 50 ảnh).

Sau khi loại bỏ những ảnh nhiều, ta tiến hành lại tìm threshold tốt nhất từ bộ train như bước 3.
Ta tìm được threshold tốt nhất là 1.45, độ chính xác khoảng 98% trên bộ train.

5. Từ threshold tìm được ta tiến hành nhận dạng trên bộ dữ liệu test.

Ta tiến hành chạy với các threshold xung quanh giá trị tốt nhất trên tập train.

```
for t in  1.30 1.35 1.40 1.45 1.50 1.55 1.60;do python ../aivivn/aivivn_vertification.py --data-dir=../data/convert/test --model-path=../models/model.pkl --idx2path=../models/idx2path.pkl --known-vector-dir=../models/vector/ --ver-vector-dir=../models/vector_test/ --threshold=$t --k=5  --batch-size=1000 --tree-path=../models/tree.pkl --output=../output/${t//['.']/''}.csv; done
```

Kết quả submiss cho thấy 1.35 là threshold có kết quả tốt nhất (0.94166 và điểm chung cuộc 0.94452)

6. Thống kê số người lạ với những threshold chạy được ở bước trước (góp phần tối ưu threshold).

```
for f in ../output/*.csv;do a=${f//.csv/};python ../aivivn/review_result.py --input_path=$f --output_path=$a.jpg;done
```
Với threshold = 1.35, ta có thống kê sau:
![image number per person](https://github.com/cuongvomanh/FaceIdentification/tree/master/resources/135.jpg)
----
