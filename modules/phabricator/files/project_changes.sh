#!/bin/bash
# send project changes in Phabricator for the last week (T85183)
# to phabricator-reports@lists.wikimedia.org (T136660)
# ! this file is managed by puppet !
# ./modules/phabricator/file/project_changes.sh

source /etc/phab_project_changes.conf

#echo "result_creations_and_name_changes"
result_creations_and_name_changes=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user $sql_name << END

SELECT CONCAT("https://phabricator.wikimedia.org/project/profile/", p1.id) AS url, project_transaction1.oldValue, project_transaction1.newValue, parent.name AS parentProject, user.userName
    FROM project_transaction project_transaction1
    LEFT OUTER JOIN
        (SELECT project.name, project_transaction2.objectPHID, project_transaction2.transactionType
        FROM project_transaction AS project_transaction2
        JOIN project
        WHERE (project_transaction2.transactionType = "project:parent"
        OR project_transaction2.transactionType = "project:milestone")
        AND SUBSTRING(project_transaction2.newValue, 2,30) = project.phid
        AND project_transaction2.dateModified > UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 1 WEEK))) parent
        ON parent.objectPHID = project_transaction1.objectPHID
    JOIN phabricator_user.user
    JOIN project p1
    WHERE project_transaction1.transactionType = "project:name"
    AND p1.phid = project_transaction1.objectPHID
    AND project_transaction1.authorPHID = user.phid
    AND project_transaction1.dateModified > UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 1 WEEK));

END
)

#echo "result_color_changes"
result_color_changes=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT CONCAT("https://phabricator.wikimedia.org/project/profile/", project.id) AS url, project_transaction.oldValue, project_transaction.newValue, project.name
    FROM project_transaction
    JOIN project
    WHERE project_transaction.transactionType = "project:color"
    AND project_transaction.objectPHID = project.phid
    AND project_transaction.dateModified > UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 1 WEEK));

END
)

#echo "result_policy_locking_archiving_changes"
result_policy_locking_archiving_changes=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT CONCAT("https://phabricator.wikimedia.org/project/profile/", project.id) AS url, project_transaction.oldValue, project_transaction.newValue,
    project_transaction.transactionType, project.name
    FROM project_transaction
    JOIN project
    WHERE (project_transaction.transactionType = "core:join-policy"
    OR project_transaction.transactionType = "core:edit-policy"
    OR project_transaction.transactionType = "core:view-policy"
    OR project_transaction.transactionType = "project:locked"
    OR project_transaction.transactionType = "project:status")
    AND (project_transaction.oldValue != "null"
        OR project_transaction.newValue NOT IN ("\"public\"", "\"users\""))
    AND project_transaction.objectPHID = project.phid
    AND project_transaction.dateModified > UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 1 WEEK));

END
)

#echo "result_column_changes"
result_column_changes=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT CONCAT("https://phabricator.wikimedia.org/project/board/", prj.id) AS url, prj.name AS projectName, cl.name AS columnName, cltr.oldValue, cltr.newValue, usr.userName
    FROM phabricator_project.project_columntransaction cltr
    JOIN phabricator_project.project prj
    JOIN phabricator_project.project_column pcl
    JOIN phabricator_user.user usr
    JOIN phabricator_project.project_column cl
    WHERE (cltr.transactionType = "project:col:name"
    OR cltr.transactionType = "project:col:status")
    AND cltr.objectPHID = pcl.phid
    AND pcl.projectPHID = prj.phid
    AND cltr.authorPHID = usr.phid
    AND cl.phid = cltr.objectPHID
    AND cltr.dateModified > UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 1 WEEK));

END
)

#echo "result_archived_projects_open_tasks"
# see https://phabricator.wikimedia.org/T133649
result_archived_projects_open_tasks=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT CONCAT("https://phabricator.wikimedia.org/project/profile/", p.id) AS url, sub.parentProject AS parentProject, p.name AS projectName, count(p.name) AS n
    FROM phabricator_maniphest.edge edg
    JOIN phabricator_maniphest.maniphest_task t
    JOIN phabricator_project.project p
    LEFT JOIN (SELECT p3.name AS parentProject, p3.phid FROM phabricator_project.project p3) sub
    ON sub.phid = p.parentProjectPHID
    WHERE edg.dst LIKE 'PHID-PROJ-%'
    AND edg.src LIKE 'PHID-TASK-%'
    AND p.phid = edg.dst
    AND p.status = 100
    AND t.phid = edg.src
    AND (t.status = "open" OR t.status = "stalled")
    AND edg.src NOT IN
    (SELECT edg2.src
    FROM phabricator_maniphest.edge edg2
    JOIN phabricator_maniphest.maniphest_task t2
    JOIN phabricator_project.project p2
    WHERE edg2.dst LIKE 'PHID-PROJ-%'
    AND edg2.src LIKE 'PHID-TASK-%'
    AND edg2.dst != "PHID-PROJ-onnxucoedheq3jevknyr"
    AND p2.phid = edg2.dst
    AND p2.status = 0
    AND t2.phid = edg2.src
    AND (t2.status = "open" OR t2.status = "stalled"))
    GROUP BY p.name
    ORDER BY n DESC;

END
)

# echo "result_problematic_color_icon_combos"
# see https://phabricator.wikimedia.org/T249806
result_problematic_color_icon_combos=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END
SELECT CONCAT("https://phabricator.wikimedia.org/project/profile/", id) AS url, name, color, icon
    FROM phabricator_project.project
    WHERE status != "100"
    AND ((color = "violet" AND icon != "group")
        OR (color = "yellow" AND icon != "tag")
        OR (color = "orange" AND (icon != "goal" AND icon != "release"))
        OR (color = "checkered" AND icon != "account")
        OR (color = "green" AND icon != "timeline")
        OR color = "indigo"
        OR (color = "grey" AND icon != "meta" AND name != "Trash"));

END
)

# echo "result_inactive_users_assigned_tasks"
# see https://phabricator.wikimedia.org/T157740
result_inactive_users_assigned_tasks=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END
SELECT CONCAT("https://phabricator.wikimedia.org/p/", u.userName) AS userName, e.src AS taskPHID, e.dst AS "projectPHID of task" 
    FROM phabricator_maniphest.maniphest_task t
    JOIN phabricator_user.user u
    JOIN phabricator_maniphest.edge e
    WHERE u.isDisabled = 1
    AND t.ownerPHID = u.phid
    AND (t.status = "open" OR t.status = "stalled")
    AND e.src = t.phid
    AND e.dst LIKE "PHID-PROJ-%"
    ORDER BY u.userName, taskPHID;

END
)

# echo "result_new_user_assignees"
# see https://phabricator.wikimedia.org/T195780
# and https://phabricator.wikimedia.org/T227388
result_new_user_assignees=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END
SELECT DISTINCT CONCAT("https://phabricator.wikimedia.org/p/", u.userName) AS userName,
    CONCAT("https://phabricator.wikimedia.org/T", t.id) AS id,
    from_unixtime(t.dateModified) AS claimedOn
    FROM phabricator_maniphest.maniphest_task t
    JOIN phabricator_user.user u ON u.userName = t.ownerOrdering
    WHERE t.dateModified > UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 6 WEEK))
    AND (t.status = "open" OR t.status = "stalled")
    AND u.dateCreated > UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 8 WEEK))
    AND u.isDisabled = 0
    AND t.ownerOrdering IS NOT NULL
    AND t.closerPHID IS NULL
    AND t.ownerOrdering IN
        (SELECT t.ownerOrdering FROM phabricator_maniphest.maniphest_task t
        JOIN phabricator_user.user u
        WHERE u.userName = t.ownerOrdering
        AND u.dateCreated > UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 8 WEEK))
        GROUP BY t.ownerOrdering HAVING COUNT(t.ownerOrdering) < 4)
    ORDER BY userName, claimedOn;

END
)

#echo "result_user_profile_urls"
# see https://phabricator.wikimedia.org/T250946
result_user_profile_urls=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user $sql_name << END
SELECT CONCAT("https://phabricator.wikimedia.org/p/", u.userName) AS userName
    FROM phabricator_user.user u
    INNER JOIN phabricator_user.user_profile up
    WHERE up.userPHID = u.phid
    AND u.isDisabled = 0
    AND up.blurb LIKE "%http%"
    AND up.dateModified > (UNIX_TIMESTAMP() - 605300);
END
)

#echo "result_workboard_column_triggers"
# see https://phabricator.wikimedia.org/T260427
result_workboard_column_triggers=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user $sql_name << END

SELECT CONCAT("https://phabricator.wikimedia.org/p/", u.userName) AS author,
    CONCAT("https://phabricator.wikimedia.org/project/board/", p.id) AS url,
    pc.name AS columnname
    FROM phabricator_project.project p
    INNER JOIN phabricator_project.project_column pc
    INNER JOIN phabricator_project.project_triggertransaction ptt
    INNER JOIN phabricator_user.user u
    WHERE pc.projectPHID = p.phid
    AND pc.triggerPHID = ptt.objectPHID
    AND ptt.transactionType = "ruleset"
    AND ptt.authorPHID = u.phid
    AND ptt.dateModified > (UNIX_TIMESTAMP() - 605300)
    ORDER BY ptt.dateModified;
END
)

#echo "result_dashboard_panels"
# see https://phabricator.wikimedia.org/T260428
result_dashboard_panels=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user $sql_name << END

SELECT CONCAT("https://phabricator.wikimedia.org/W", dp.id) AS panel,
    u.userName AS author,
    u.isDisabled AS disabled,
    dp.name AS panelName,
    dp.viewPolicy AS viewPolicy
    FROM phabricator_dashboard.dashboard_panel dp
    INNER JOIN phabricator_user.user u
    WHERE dp.authorPHID = u.phid
    AND dp.dateModified > (UNIX_TIMESTAMP() - 605300)
    ORDER BY dp.dateModified;
END
)

#echo "result_past_due_dates"
# see https://phabricator.wikimedia.org/T249807
result_past_due_dates=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user $sql_name << END
SELECT CONCAT("https://phabricator.wikimedia.org/T", t.id) AS Task, FROM_UNIXTIME(cfs.fieldValue) AS DueDate
    FROM phabricator_maniphest.maniphest_task t
    JOIN phabricator_maniphest.maniphest_customfieldstorage cfs
    WHERE cfs.fieldIndex = "GGorRQHBaRdo"
    AND FROM_UNIXTIME(cfs.fieldValue) < (NOW() - INTERVAL 1 MONTH)
    AND t.phid = cfs.objectPHID
    AND (t.status = "open" OR t.status = "stalled")
    ORDER BY cfs.fieldValue;
END
)

#echo "result_parent_projects_without_desc"
# see https://phabricator.wikimedia.org/T249805
result_parent_projects_without_desc=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user $sql_name << END
SELECT CONCAT("https://phabricator.wikimedia.org/tag/", p.primarySlug) AS parentproject
    FROM phabricator_project.project p
    WHERE p.parentProjectPHID IS NULL
    AND p.status != 100
    AND p.phid NOT IN
        (SELECT p.phid
        FROM phabricator_project.project p
        JOIN phabricator_project.project_customfieldstorage cfs
        WHERE cfs.objectPHID = p.phid
        AND fieldIndex = "0.9QWd3nmyTs")
    ORDER BY p.primarySlug;
END
)

#echo "result_sub_projects_without_desc"
# see https://phabricator.wikimedia.org/T249805
result_sub_projects_without_desc=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user $sql_name << END
SELECT CONCAT("https://phabricator.wikimedia.org/tag/", pp.primarySlug) AS parentproject, p.name AS subproject
    FROM phabricator_project.project p
    JOIN phabricator_project.project pp
    WHERE pp.phid = p.parentProjectPHID
    AND pp.status != 100
    AND p.status != 100
    AND p.phid NOT IN
        (SELECT p.phid
        FROM phabricator_project.project p
        JOIN phabricator_project.project_customfieldstorage cfs
        WHERE p.status != 100
        AND cfs.objectPHID = p.phid
        AND fieldIndex = "0.9QWd3nmyTs")
    ORDER BY pp.primarySlug,p.name;
END
)

#echo "result_herald_rules"
result_herald_rules=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u $sql_user $sql_name << END
 SELECT CONCAT("https://phabricator.wikimedia.org/H", h.id) AS heraldRule,
    u.userName AS author
    FROM phabricator_herald.herald_rule h
    INNER JOIN phabricator_user.user u
    WHERE h.authorPHID = u.phid
    AND h.isDisabled = 0
    AND h.authorPHID NOT IN
        (SELECT trs.authorPHID FROM phabricator_maniphest.maniphest_transaction trs
        INNER JOIN phabricator_user.user u
        WHERE FROM_UNIXTIME(trs.dateModified) >= (NOW() - INTERVAL 6 MONTH)
        AND trs.authorPHID = u.phid)
    ORDER BY heraldRule;
END
)

# echo "result_cookie_licked_tasks"
# see https://phabricator.wikimedia.org/T228575
result_cookie_licked_tasks=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT CONCAT("https://phabricator.wikimedia.org/T", t.id) AS taskID, u.userName, from_unixtime(ta.dateModified) AS since
    FROM phabricator_maniphest.maniphest_task t
    JOIN phabricator_user.user u
    JOIN phabricator_maniphest.maniphest_transaction ta
    WHERE (ta.transactionType = "reassign"
    AND ta.dateModified < (UNIX_TIMESTAMP() - 126144000))
    AND u.phid = SUBSTR(ta.newValue, INSTR(ta.newValue, 'PHID-USER-'), 30)
    AND ta.objectPHID = t.phid
    AND t.ownerPHID = u.phid
    AND (t.status = "open" OR t.status = "stalled")
    AND t.phid NOT IN
        (SELECT ta.objectPHID FROM phabricator_maniphest.maniphest_transaction ta
        WHERE (ta.transactionType = "reassign"
        AND ta.dateModified > (UNIX_TIMESTAMP() - 126144000)))
    ORDER BY ta.dateModified;

END
)

# echo "result_cookie_licked_tasks_bz"
# see https://phabricator.wikimedia.org/T274711
result_cookie_licked_tasks_bz=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT CONCAT("https://phabricator.wikimedia.org/T", t.id) AS taskID, u.userName
    FROM phabricator_maniphest.maniphest_task t
    JOIN phabricator_user.user u
    WHERE t.id < 75681
    AND t.ownerPHID IS NOT NULL
    AND t.ownerPHID = u.phid
    AND (t.status = "open" OR t.status = "stalled")
    AND t.phid NOT IN (SELECT ta.objectPHID FROM phabricator_maniphest.maniphest_transaction ta WHERE ta.transactionType = "reassign")
    ORDER BY t.id;

END
)

# echo "result_old_stalled_tasks"
# see https://phabricator.wikimedia.org/T252522
result_old_stalled_tasks=$(MYSQL_PWD=${sql_pass} /usr/bin/mysql -h $sql_host -P $sql_port -u$sql_user $sql_name << END

SELECT CONCAT("https://phabricator.wikimedia.org/T", mt.id) AS taskID,
IF (mt.viewPolicy = "public", mt.title, "---restricted---") as taskTitle,
FROM_UNIXTIME(mta1.dateCreated) AS stalled_date
    FROM phabricator_maniphest.maniphest_task mt
    JOIN phabricator_user.user u ON u.phid=mt.authorPHID
    INNER JOIN phabricator_maniphest.maniphest_transaction mta1
    WHERE mt.status = "stalled"
    AND mt.phid NOT IN
        (SELECT e.src FROM phabricator_maniphest.edge e
        WHERE e.type = 41
        AND e.dst="PHID-PROJ-bchzb6qpl3jhgs2oq6um")
    AND mt.phid NOT IN
        (SELECT e.src FROM phabricator_maniphest.edge e
        WHERE e.type = 3)
    AND mt.phid = mta1.objectPHID
    AND mta1.transactionType = "status"
    AND mta1.newValue = "\"stalled\""
    AND FROM_UNIXTIME(mta1.dateCreated) <= (NOW() - INTERVAL 36 MONTH)
    AND mt.phid NOT IN
        (SELECT mta2.objectPHID FROM phabricator_maniphest.maniphest_transaction mta2
        WHERE mta2.transactionType = "status"
        AND mta2.newValue = "\"stalled\""
        AND FROM_UNIXTIME(mta2.dateCreated) >= (NOW() - INTERVAL 36 MONTH))
    ORDER BY mta1.dateCreated;

END
)

# the actual email
cat <<EOF | /usr/bin/mail -r "${sndr_address}" -s "Phabricator weekly project changes" ${rcpt_address}

Hi Phabricator admin,

This is your automatic weekly Phabricator project changes mail.


PROJECT CREATIONS AND PROJECT NAME CHANGES:
${result_creations_and_name_changes}


PROJECT COLOR CHANGES:
${result_color_changes}


PROJECT POLICY/LOCKING/ARCHIVING CHANGES:
${result_policy_locking_archiving_changes}


PROJECT WORKBOARD COLUMN CHANGES:
(newValue and oldValue values: 0 = shown, 1 = hidden)
${result_column_changes}


ARCHIVED PROJECTS WITH OPEN TASKS WITH NO OTHER ACTIVE PROJECTS, EXCLUDING PATCH-FOR-REVIEW:
${result_archived_projects_open_tasks}


PROJECTS WITH COLOR/ICON COMBINATIONS WHICH MIGHT VIOLATE OUR GUIDELINES:
${result_problematic_color_icon_combos}


DISABLED USER ACCOUNTS WITH OPEN TASKS ASSIGNED:
${result_inactive_users_assigned_tasks}


USER ACCOUNTS WHO BECAME AN ASSIGNEE LAST WEEK AND HAD LESS THAN 5 TASKS EVER ASSIGNED:
${result_new_user_assignees}


USER PROFILES WITH A URL IN THEIR DESC WHICH CHANGED WITHIN THE LAST 1 WEEK (to spam check):
${result_user_profile_urls}


WORKBOARD COLUMN TRIGGER CHANGES WITHIN THE LAST 1 WEEK (to spam check):
${result_workboard_column_triggers}


DASHBOARD PANEL CHANGES WITHIN THE LAST 1 WEEK (to spam check):
${result_dashboard_panels}


OPEN TASKS WITH A DUE DATE MORE THAN 1 MONTH AGO:
${result_past_due_dates}


PROJECTS WHICH HAVE AN EMPTY PROJECT DESCRIPTION:
${result_parent_projects_without_desc}

${result_sub_projects_without_desc}


ACTIVE HERALD RULES AUTHORED BY ACCOUNTS INACTIVE FOR 6 MONTHS:
${result_herald_rules}


OPEN TASKS THAT HAVE BEEN ASSIGNED TO THE SAME USER FOR MORE THAN FOUR YEARS:
${result_cookie_licked_tasks}
${result_cookie_licked_tasks_bz}


STALLED TASKS THAT HAVE BEEN STALLED FOR MORE THAN THREE YEARS:
${result_old_stalled_tasks}

Yours sincerely,
Fab Rick Aytor

(via $(basename $0) on $(hostname) at $(date))
EOF
