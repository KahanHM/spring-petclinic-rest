# Web Server Setup with Python and Docker

This Ansible playbook sets up web servers by ensuring Python is present and then installing Docker.

## Files

* `playbook.yml`: The main Ansible playbook.
* `inventory.ini`: Lists the target servers.
* `requirements.yml`: Lists required Ansible Galaxy roles.
* `vars.yml`: Contains variables for Docker setup.

## Prerequisites

* Ansible installed on your control machine.
* SSH access with sudo privileges to your target servers.

## Setup & Run

1.  **Create `requirements.yml`:**
    ```yaml
    # requirements.yml
    - src: robertdebock.bootstrap
    - src: geerlingguy.docker
    ```

2.  **Install Roles:**
    ```bash
    ansible-galaxy install -r requirements.yml
    ```

3.  **Create `inventory.ini`:**
    ```ini
    # inventory.ini
    [web]
    your_server_name ansible_host=<manager-ip>  ansible_user=your_ssh_user ansible_ssh_private_key_file=/path/to/key.pem
    #if you need more add same way
    #example
   server1 ansible_host=10.10.10.10 ansible_user=user1 ansible_ssh_private_key_file="/home/user1/key/Testing.pem"
    ```
    *Replace placeholders with your actual server details.*

4.  **Create `vars.yml`:**
    ```yaml
    # vars.yml
    docker_users:
      - your_ssh_user # Add user to docker group
    docker_install_compose: true
    ```

5.  **Run Playbook:**
    ```bash
    ansible-playbook -i inventory.ini playbook.yml --ask-become-pass
    ```

---

**Note:** For the playbook content itself, make sure your original `main.yml` is renamed to `playbook.yml` and `vars/docker.yml` is renamed to `vars.yml` for this `README` to be accurate.

**Original playbook content (to be named `playbook.yml`):**
```yaml
---
- name: Install python if not
  hosts: web
  become: true
  gather_facts: false
  roles:
    - role: robertdebock.bootstrap

- name: Install Docker with geerlingguy.docker
  hosts: web
  become: true
  gather_facts: false

  vars_files:
    - vars.yml # Changed from vars/docker.yml

  roles:
    - geerlingguy.docker