import os
import csv
from supabase import create_client, Client

def load_env():
  """
  Loads environment variables from the .env file into the system path.
  """
  if os.path.exists(".env"):
    with open(".env") as f:
      for line in f:
        # In case there is redundant space
        line = line.strip()

        # .startswith("#") prevent using comment lines
        if "=" in line and not line.startswith("#"):
          # .split("=", 1) splits the string at "equal sign" and only at "the first one" (in case there are other equal signs in the value)
          key, value = line.split("=", 1)
          # In case using single or double quotes by accident
          # len(value) >= 2 prevents error if the value is only one character
          if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
            value = value[1: -1]
          # Once this line runs, we can access the variable anywhere else in programming using "os.getenv(key)"
          os.environ[key] = value

def load_csv_to_supabase(file_path, supabase_client):
  print(f"Start uploading data from {file_path} to Supabase...")

  batch_size = 500
  data = []
  total_row_count = 0

  try:
    with open(file_path, mode="r", encoding="utf-8") as f:
      reader = csv.DictReader(f)

      for idx, row in enumerate(reader):
        # Transfer data format
        data.append({
          "event_time": row["datetime"],
          "source_ip": row["source_ip"],
          "protocol": row["protocol"],
          "target_port": int(row["target_port"]) if row["target_port"] else None,
          "country_code": row["country"],
          "risk_level": row["risk_level"]
        })

        total_row_count += 1

        if len(data) == batch_size:
          # Insert into Supabase
          res = supabase_client.table("honeypot_logs").insert(data).execute()
          
          print(f"Progress: {idx + 1} rows uploaded")
          # Reset data list
          data = []

      # Dealing with the rest of data that does not satisfy "batch_size"
      if data:
        # Insert into Supabase
        res = supabase_client.table("honeypot_logs").insert(data).execute()
        print(f"Progress: Final {len(data)} rows uploaded")

    print(f"Successfully uploaded total {total_row_count} rows.")

  except Exception as e:
    print(f"Error during uploading: {e}")

if __name__ == "__main__":
  load_env()
  url: str = os.environ.get("SUPABASE_URL")
  key: str = os.environ.get("SUPABASE_SERVICE_KEY")
  supabase_client: Client = create_client(url, key)

  load_csv_to_supabase("data/processed/refined_logs.csv", supabase_client)