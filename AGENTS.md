# AGENTS.md
## Project Overview
This is an ETL pipeline processing raw AWS Honeypot logs.
Core objectives:
1. ETL on unstructured logs
2. PII de-identification (IP masking)
3. The use of Cloudflare Workers and Supabase
4. Automated CI/CD workflow
5. Collaborate with Claude Code
## Tech Stack
- **Language**: Python 3.x
- **Database**: Supabase (PostgreSQL)
- **Serverless**: Cloudflare Workers
- **CI/CD**: GitHub Actions
- **Data Processing**: re (Regex), pandas (if needed for analysis)
## Code Style Guidelines

## Security Considerations