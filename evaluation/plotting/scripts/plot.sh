#!/usr/bin/env bash

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <site1> <site2>" >&2
  exit 1
fi

cd "$(realpath "$(dirname "$0")")"

./merge_sites.sh "$@"
python3 preprocess.py
python3 plot.py

mv "$(ls -dt ../figures/*/ | head -n1)"/* /var/www/html/

echo "Plots are available at:"
hostname=$(cat /var/www/html/hostname)
echo "  Fig.4: http://$hostname/fig4.pdf"
echo "  Fig.5: http://$hostname/fig5.pdf"
echo "  Fig.7: http://$hostname/fig7.pdf"
echo "  Fig.8: http://$hostname/fig8.pdf"