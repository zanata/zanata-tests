
import checkxml


EXPECTED_SOURCES = {
        'stage2/test.xml': {
                u'flow1': {
                    'revision' : u'1',
                    'content' : u'source 1 changed',
                },
                u'flow2': {
                    'revision' : u'1',
                    'content' : u'source 2 different',
                },
                u'flow3': {
                    'revision' : u'1',
                    'content' : u'source 3',
                },
                u'flow4': {
                    'revision' : u'1',
                    'content' : u'source 4 changed',
                },
                u'flow5': {
                    'revision' : u'1',
                    'content' : u'source 5 different',
                },
                u'flow6': {
                    'revision' : u'1',
                    'content' : u'source 6',
                },
                u'flow7': {
                    'revision' : u'1',
                    'content' : u'source 7 changed',
                },
                u'flow8': {
                    'revision' : u'1',
                    'content' : u'source 8 different',
                },
                u'flow9': {
                    'revision' : u'1',
                    'content' : u'source 9',
                },
        },
}



EXPECTED_TARGETS = {
        'stage2/test_es_SP.xml': {
                u'flow9': {
                    'revision' : u'1', #TODO look at pushing another flow9 translation to make the copied-from revision different so that this check is meaningful
                    'state' : u'Approved',
                    'resourceRevision' : u'1',
                    'content' : u'v1.0 es approved 3',
                },
        },
        
        #TODO should this be present?
        'stage2/test_de_DE.xml': {
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

