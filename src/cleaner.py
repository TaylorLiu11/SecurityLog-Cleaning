import csv
import os
from datetime import datetime, timezone

def mask_ip(raw_ip):
  # Implement PII Masking
  if not raw_ip or "." not in raw_ip:
    return "0.0.0.x"
  # .rsplit() split from the right side
  return raw_ip.rsplit(".", 1)[0] + ".x"

def get_risk_level(raw_port):
  # Check high risk: 22 (SSH), 23 (Telnet), 3389 (RDP), 445 (SMB)
  high_risk_ports = [22, 23, 3389, 445]
  try:
    # Parse int from str
    port = int(raw_port)
    if port in high_risk_ports:
      return "High"
    return "Low"
  # In case the field is empty or the format is something unexpected
  except:
    return "Unknown"

def run_etl(input_file, output_file):
  # Use timezone.utc to make sure UTC format
  print(f"[{datetime.now(timezone.utc)}] Start processing file: {input_file}")

  # Check if path exists
  if not os.path.exists(input_file):
    print("Original file not found. Please check the path again.")
    return
  
  # Extract
  # "with" keyword ensures the file is automatically closed right after the code inside the block finishes. This prevents creating "memory leak".
  with open(input_file, mode="r", encoding="utf-8") as f_input:
    # csv.DictReader() takes the first row and uses those names as keys (e.g. row["proto"])
    reader = csv.DictReader(f_input)

    cleaned_data = []
    for row in reader:
      clean_row = {
        "datetime": row.get("datetime"),
        "source_ip": mask_ip(row.get("srcstr")),
        "protocol": row.get("proto"),
        "target_port": row.get("dpt"),
        "country": row.get("cc"),
        "risk_level": get_risk_level(row.get("dpt"))
      }
      cleaned_data.append(clean_row)

  # Check if "cleaned_data" list is empty
  if not cleaned_data:
    print("No data was processed. Output file will not be created.")
    return

  keys = cleaned_data[0].keys()
  with open(output_file, "w", newline="") as f_out:
    # Use "fieldnames=keys" to make sure the columns are correct
    dict_writer = csv.DictWriter(f_out, fieldnames=keys)
    # .writeheader() writes the strings we provide in "fieldnames=keys"
    dict_writer.writeheader()
    dict_writer.writerows(cleaned_data)

  print(f"Cleaned! Total rows of data processed: {len(cleaned_data)}")
  print(f"Result is saved in: {output_file}")

if __name__ == "__main__":
  # Execute ETL
  run_etl("data/raw/AWS_Honeypot_marx-geo.csv", "data/processed/refined_logs.csv")