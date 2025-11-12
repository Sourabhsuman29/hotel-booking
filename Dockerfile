# Use Python 3.12 slim base image
FROM python:3.12-slim

# Install system dependencies for Playwright and Xvfb
RUN apt-get update && apt-get install -y \
    curl wget gnupg xvfb x11-utils \
    libnss3 libatk-bridge2.0-0 libx11-xcb1 libxcomposite1 libxdamage1 libxrandr2 \
    libgbm1 libasound2 libxshmfence1 libxext6 libxfixes3 libegl1 libfontconfig1 \
    libharfbuzz0b libpango-1.0-0 libpangocairo-1.0-0 libgtk-3-0 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /tests

# Copy project files into container
COPY . /tests

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright browsers
RUN python -m playwright install --with-deps

# Set PYTHONPATH so Robot can find custom libraries
ENV PYTHONPATH=/tests/ui/Library

# Run Robot Framework tests in headed mode using Xvfb
# CMD ["xvfb-run", "robot", "-d", "results", "SasRestLibrary/reqres_api_tests/end-to-end-suite.robot"]
# CMD ["xvfb-run", "--server-args=-screen 0 1920x1080x24", "robot", "-d", "results", "SasRestLibrary/reqres_api_tests/end-to-end-suite.robot"]
CMD ["robot", "-d", "results", "tests/e2e_application_flow.robot"]
#CMD ["xvfb-run", "robot", "-d", "results", "tests/e2e_application_flow.robot"]








