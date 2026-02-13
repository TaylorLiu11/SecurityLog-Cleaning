# AGENTS.md
## Project Overview
This is an ETL pipeline processing raw AWS Honeypot logs.
Core objectives:
1. ETL on unstructured logs
2. PII de-identification (IP masking)
3. The use of Cloudflare Workers and Supabase
4. Automated CI/CD workflow
5. Collaborate with Claude Code to create index.html
## Tech Stack
- **Language**: Python 3.x
- **Database**: Supabase (PostgreSQL)
- **Serverless**: Cloudflare Workers, Cloudflare Pages
- **CI/CD**: GitHub Actions
- **Frontend**: Claude Code
## Code Style Guidelines
- **Robustness**: Check for directory existence before file I/O using `os.path.exists`, using try/except to gracefully catch errors.
- **Documentation**: Explain lines of code using detailed comments.
- **Logging**: Use structured print statements to show ETL progress.
## Security Considerations
- **ENV File Management**: Always use env file to pass in credentials.
## Agent Role
1. Prioritize **security** and **data integrity**.
2. Prefer **standard libraries** unless necessary.