git clone --recursive https://github.com/deepinsight/insightface.git
cd insightface
virtualenv -p python2 env
source env/bin/activate
pip install -r ../requirements.txt
