# Web Server Setup with Python and Docker

This Ansible playbook sets up web servers by ensuring Python is present and then installing Docker.

## Files

* `playbook.yml`: The main Ansible playbook.
* `inventory.ini`: Lists the target servers.
* `requirements.yml`: Lists required Ansible Galaxy roles.
* `vars/docker.yml`: Contains variables for Docker setup.
* `vars/swarm.yml`: Contains variables for Docker setup.

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

4.  **Create `vars/vars.yml`:**
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
- name: Install system dependencies
  hosts: all
  become: true
  gather_facts: false
  roles:
    - role: robertdebock.bootstrap

- name: Install Docker
  hosts: all
  become: true
  gather_facts: false
  vars_files:
    - vars/docker.yml
  roles:
    - geerlingguy.docker

- name: Initialize Docker Swarm on Manager (CLI version)
  hosts: manager
  become: yes
  vars_files:
    - vars/swarm.yml
  tasks:
    - name: Check if swarm already initialized
      command: docker info --format '{{ '{{.Swarm.LocalNodeState}}' }}'
      register: swarm_status
      changed_when: false
      ignore_errors: yes

    - name: Init Swarm if not already initialized
      command: docker swarm init --advertise-addr {{ manager_ip }}
      when: swarm_status.stdout != "active" or swarm_status.rc != 0

- name: Get join token from manager
  hosts: manager
  tags: swram
  become: yes
  vars_files:
    - vars/swarm.yml
  tasks:
    - name: Get worker join token
      command: docker swarm join-token -q worker
      register: worker_token

    - name: Add token as a global host var
      add_host:
        name: swarm_token_holder
        swarm_join_token_global: "{{ worker_token.stdout }}"


- name: Join Worker to Swarm (CLI version)
  hosts: worker
  tags: swram
  become: yes
  vars_files:
    - vars/swarm.yml
  tasks:
    - name: Check if node is already in swarm
      command: docker info --format '{{ '{{.Swarm.LocalNodeState}}' }}'
      register: node_swarm_status
      changed_when: false
      ignore_errors: yes

    
    - name: Join the swarm as a worker
      command: >
        docker swarm join
        --token {{ hostvars['swarm_token_holder']['swarm_join_token_global'] }}
        --advertise-addr {{ worker_ip }}
        {{ manager_ip }}:2377
      when: node_swarm_status.stdout != "active" or node_swarm_status.rc != 0