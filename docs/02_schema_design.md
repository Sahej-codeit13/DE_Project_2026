
# Schema Design

## 1. Introduction

This document describes the relational database schema for the LinkedIn-style professional networking platform.

The database is designed using relational database principles and follows normalization rules to reduce data redundancy and maintain data integrity.

## 2. Database Schema

All tables will be created inside the `linkedin` schema in PostgreSQL.

The database contains the following 12 tables:

1. cities
2. members
3. companies
4. positions
5. skills
6. member_skills
7. jobs
8. job_skills
9. applications
10. connections
11. invitations
12. profile_views

## 3. Table Descriptions

### 3.1 cities
Stores city and state information.

- Primary Key: city_id
- Attributes: city_name, state

### 3.2 members
Stores professional profile information of platform members.

- Primary Key: member_id
- Foreign Key: city_id references cities(city_id)
- Attributes: first_name, last_name, headline, email, industry, is_premium, open_to_work, created_at

### 3.3 companies
Stores company information.

- Primary Key: company_id
- Foreign Key: hq_city_id references cities(city_id)
- Attributes: company_name, industry, company_size, founded_year, website

### 3.4 positions
Stores members' professional work experience.

- Primary Key: position_id
- Foreign Keys:
  - member_id references members(member_id)
  - company_id references companies(company_id)
- Attributes: title, employment_type, start_date, end_date

### 3.5 skills
Stores the list of available professional skills.

- Primary Key: skill_id
- Attributes: skill_name

### 3.6 member_skills
Maps members to their skills.

- Composite Primary Key: (member_id, skill_id)
- Foreign Keys:
  - member_id references members(member_id)
  - skill_id references skills(skill_id)
- Additional Attribute: endorsements

### 3.7 jobs
Stores job postings created by companies.

- Primary Key: job_id
- Foreign Keys:
  - company_id references companies(company_id)
  - city_id references cities(city_id)
- Attributes: title, workplace_type, employment_type, min_experience, min_salary_lpa, max_salary_lpa, posted_at, closes_at, status

### 3.8 job_skills
Maps jobs to the skills required for them.

- Composite Primary Key: (job_id, skill_id)
- Foreign Keys:
  - job_id references jobs(job_id)
  - skill_id references skills(skill_id)

### 3.9 applications
Stores job applications submitted by members.

- Primary Key: application_id
- Foreign Keys:
  - job_id references jobs(job_id)
  - member_id references members(member_id)
- Attributes: applied_at, easy_apply, status, status_updated_at

### 3.10 connections
Stores connections between two members.

- Composite Primary Key: (member_a, member_b)
- Foreign Keys:
  - member_a references members(member_id)
  - member_b references members(member_id)
- Additional Attribute: connected_at

### 3.11 invitations
Stores connection requests sent between members.

- Primary Key: invitation_id
- Foreign Keys:
  - sender_id references members(member_id)
  - recipient_id references members(member_id)
- Attributes: note, sent_at, status, responded_at

### 3.12 profile_views
Stores records of members viewing other members' profiles.

- Primary Key: view_id
- Foreign Keys:
  - viewer_id references members(member_id)
  - viewed_id references members(member_id)
- Additional Attribute: viewed_at
- Note: viewer_id can be NULL for anonymous profile views.

## 4. Relationships and Cardinality

- One city can have many members.
- One city can be the headquarters location for many companies.
- One city can have many jobs.
- One company can have many positions and jobs.
- One member can have many positions.
- Members and skills have a many-to-many relationship through member_skills.
- Jobs and skills have a many-to-many relationship through job_skills.
- Members and jobs have a many-to-many relationship through applications.
- Members can connect with other members through connections.
- Members can send and receive multiple invitations.
- Members can view multiple profiles and have their profiles viewed by others.

## 5. Normalization

### First Normal Form (1NF)

- Every table contains atomic values.
- Each table has a primary key.
- There are no repeating groups or multivalued attributes.
- Skills are stored separately instead of as comma-separated values.

### Second Normal Form (2NF)

- The database satisfies 1NF.
- Every non-key attribute depends on the complete primary key.
- In member_skills, endorsements depends on the combination of member_id and skill_id.
- In job_skills, there are no non-key attributes.

### Third Normal Form (3NF)

- The database satisfies 2NF.
- There are no transitive dependencies among non-key attributes.
- City details are stored separately in cities.
- Company details are stored separately in companies.
- Skill names are stored separately in skills.

## 6. Integrity Constraints

The database will use:

- Primary key constraints to uniquely identify records.
- Foreign key constraints to maintain referential integrity.
- UNIQUE constraints for member email addresses.
- NOT NULL constraints for mandatory attributes.
- CHECK constraints for valid status and category values where appropriate.

## 7. Design Considerations

- Composite primary keys are used in junction tables.
- Foreign keys connect related entities.
- NULL values are used for missing optional data.
- The schema is designed to minimize redundancy and maintain consistency.
