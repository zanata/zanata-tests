
import checkxml


EXPECTED_SOURCES = {
        'stage1/test.xml': {
                u'flow1': {
                    'revision' : u'2',
                    'content' : u'source 1 changed',
                },
                u'flow2': {
                    'revision' : u'1',
                    'content' : u'source 2',
                },
                u'flow3': {
                    'revision' : u'1',
                    'content' : u'source 3',
                },
                u'flow4': {
                    'revision' : u'2',
                    'content' : u'source 4 changed',
                },
                u'flow5': {
                    'revision' : u'1',
                    'content' : u'source 5',
                },
                u'flow6': {
                    'revision' : u'1',
                    'content' : u'source 6',
                },
                u'flow7': {
                    'revision' : u'2',
                    'content' : u'source 7 changed',
                },
                u'flow8': {
                    'revision' : u'1',
                    'content' : u'source 8',
                },
                u'flow9': {
                    'revision' : u'1',
                    'content' : u'source 9',
                },
        },
}



EXPECTED_TARGETS = {
        'stage1/test_es_SP.xml': {
                # flow1, flow2, flow3 should not be present
                # NOTE: setting fuzzy seems to bump the revision an extra time
                # so fuzzies have rev 2, flow7 has rev 3
                # TODO check that this is acceptable behaviour
                u'flow4': {
                    'revision' : u'2',
                    'state' : u'NeedReview',
                    'resourceRevision' : u'1',
                    'content' : u'v1.0 es fuzzy 1',
                },
                u'flow5': {
                    'revision' : u'2',
                    'state' : u'NeedReview',
                    'resourceRevision' : u'1',
                    'content' : u'v1.0 es fuzzy 2',
                },
                u'flow6': {
                    'revision' : u'2',
                    'state' : u'NeedReview',
                    'resourceRevision' : u'1',
                    'content' : u'v1.0 es fuzzy 3',
                },
                u'flow7': {
                    'revision' : u'3',
                    'state' : u'NeedReview',
                    'resourceRevision' : u'1',
                    'content' : u'v1.0 es approved 1',
                },
                u'flow8': {
                    'revision' : u'1',
                    'state' : u'Approved',
                    'resourceRevision' : u'1',
                    'content' : u'v1.0 es approved 2',
                },
                u'flow9': {
                    'revision' : u'1',
                    'state' : u'Approved',
                    'resourceRevision' : u'1',
                    'content' : u'v1.0 es approved 3',
                },
        },
        'stage1/test_de_DE.xml': {
                # most flows should not be present
                u'flow3': {
                    'revision' : u'1',
                    'state' : u'Approved',
                    'resourceRevision' : u'1',
                    'content' : u'approved de target 3 in version 1.0',
                },
                u'flow6': {
                    'revision' : u'1',
                    'state' : u'Approved',
                    'resourceRevision' : u'1',
                    'content' : u'approved de target 6 in version 1.0',
                },
                u'flow9': {
                    'revision' : u'1',
                    'state' : u'Approved',
                    'resourceRevision' : u'1',
                    'content' : u'approved de target 9 in version 1.0',
                },
        },
}

checkxml.checkSourceDocs(EXPECTED_SOURCES)
checkxml.checkTargetDocs(EXPECTED_TARGETS)

