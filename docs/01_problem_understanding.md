# Problem Understanding

## 1. Introduction

The project aims to design and implement a relational database
for a professional networking platform similar to LinkedIn.

The platform allows users to create professional profiles,
connect with other members, list their skills, explore job
opportunities, apply for jobs, and interact with companies.

## 2. Objectives

The main objectives are:

- Store member profile information.
- Maintain company and location details.
- Track members' professional experience.
- Maintain skills associated with members.
- Allow companies to post job opportunities.
- Store job applications and their statuses.
- Manage member connections and invitations.
- Track profile views.

## 3. Dataset Overview

The database is based on 12 CSV files containing 1,065,104
records in total.

| CSV File | Number of Records |
|---|---:|
| applications.csv | 149,984 |
| cities.csv | 10 |
| companies.csv | 2,000 |
| connections.csv | 219,966 |
| invitations.csv | 60,000 |
| jobs.csv | 15,000 |
| job_skills.csv | 65,719 |
| member_skills.csv | 212,417 |
| members.csv | 40,000 |
| positions.csv | 99,940 |
| profile_views.csv | 199,996 |
| skills.csv | 72 |

## 4. Main Entities

The database contains the following entities:

1. Members
2. Cities
3. Companies
4. Positions
5. Skills
6. Member Skills
7. Jobs
8. Job Skills
9. Applications
10. Connections
11. Invitations
12. Profile Views

## 5. Scope

The database supports professional networking activities,
including profile management, professional connections,
job postings, job applications, skill management, and
profile-view tracking.

## 6. Assumptions

- Each member has a unique member ID and email address.
- Each company has a unique company ID.
- Each job has a unique job ID.
- Each skill has a unique skill ID.
- A member can have multiple professional positions.
- A member can possess multiple skills.
- A job can require multiple skills.
- Members can send and receive connection invitations.
- A profile view records both the viewer and the viewed member.

## 7. Database Platform

The database will be implemented using PostgreSQL 15 or later.
All tables will be created inside the `linkedin` schema.