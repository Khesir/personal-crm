import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'issue.dart';

extension IssueStatusDisplay on IssueStatus {
  String get label => switch (this) {
        IssueStatus.backlog => 'Backlog',
        IssueStatus.ready => 'Ready',
        IssueStatus.inprogress => 'In Progress',
        IssueStatus.qa => 'QA',
        IssueStatus.done => 'Done',
      };

  Color get color => switch (this) {
        IssueStatus.backlog => AppColors.statusBacklog,
        IssueStatus.ready => AppColors.statusReady,
        IssueStatus.inprogress => AppColors.statusInProgress,
        IssueStatus.qa => AppColors.statusQa,
        IssueStatus.done => AppColors.statusDone,
      };
}
