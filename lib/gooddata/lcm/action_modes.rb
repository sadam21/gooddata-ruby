require_relative 'actions/actions'

module GoodData
  module LCM2
    MODES = {
      # Low Level Commands

      actions: [
        PrintActions
      ],

      hello: [
        HelloWorld
      ],

      modes: [
        PrintModes
      ],

      info: [
        PrintTypes,
        PrintActions,
        PrintModes
      ],

      types: [
        PrintTypes
      ],

      ## Bricks

      release: [
        EnsureReleaseTable,
        CollectDataProduct,
        SegmentsFilter,
        CreateSegmentMasters,
        EnsureTechnicalUsersDomain,
        EnsureTechnicalUsersProject,
        SynchronizeLdm,
        CollectLdmObjects,
        CollectMeta,
        CollectTaggedObjects,
        CollectComputedAttributeMetrics,
        ImportObjectCollections,
        SynchronizeComputedAttributes,
        SynchronizeProcesses,
        SynchronizeSchedules,
        SynchronizeColorPalette,
        SynchronizeUserGroups,
        SynchronizeNewSegments,
        UpdateReleaseTable
      ],

      provision: [
        EnsureReleaseTable,
        CollectDataProduct,
        CollectSegments,
        CollectClientProjects,
        PurgeClients,
        CollectClients,
        AssociateClients,
        RenameExistingClientProjects,
        ProvisionClients,
        EnsureTechnicalUsersDomain,
        EnsureTechnicalUsersProject,
        CollectDymanicScheduleParams,
        SynchronizeETLsInSegment
      ],

      rollout: [
        EnsureReleaseTable,
        CollectDataProduct,
        CollectSegments,
        CollectSegmentClients,
        EnsureTechnicalUsersDomain,
        EnsureTechnicalUsersProject,
        SynchronizeLdm,
        SynchronizeClients,
        SynchronizeComputedAttributes,
        CollectDymanicScheduleParams,
        SynchronizeETLsInSegment
      ],

      users: [
        CollectDataProduct,
        CollectSegments,
        SynchronizeUsers
      ],

      user_filters: [
        CollectDataProduct,
        CollectUsersBrickUsers,
        CollectSegments,
        SynchronizeUserFilters
      ],

      schedules_execution: [
        ExecuteSchedules
      ],

      hello_world: [
        HelloWorld
      ]
    }

    MODE_NAMES = MODES.keys
  end
end
