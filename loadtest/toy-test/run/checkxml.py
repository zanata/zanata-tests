
from xml.dom import minidom
import sys

SOURCE_ELEMENT = 'ns2:text-flow'
TARGET_ELEMENT = 'ns2:text-flow-target'

SOURCE_ID_ATTRIB = 'id'
TARGET_ID_ATTRIB = 'res-id'


def checkSourceDocs(expected):
    """Check all the expected documents in the expected list"""
    
    passChecks = True
    for doc in expected.keys():
        passChecks = passChecks and checkSourceDoc(doc, expected)
    printPass(passChecks)
    return passChecks



def checkSourceDoc(docName, expected):
    """Load and check an xml document against the expected values"""
    
    missing, extra, match, nomatch = checkDoc(docName, expected, SOURCE_ELEMENT, SOURCE_ID_ATTRIB)
    print "  Checked sources in {0}. Missing: {1}. Extra: {2}. Matching: {3}. Not matching: {4}".format(docName, missing, extra, match, nomatch)
    return len(missing) == 0 and len(extra) == 0 and nomatch == 0



def checkTargetDocs(expected):
    """Check all the expected documents in the expected list"""
    
    passChecks = True
    for doc in expected.keys():
        passChecks = passChecks and checkTargetDoc(doc, expected)
    printPass(passChecks)
    return passChecks


def checkTargetDoc(docName, expected):
    """Load and check an xml document against the expected values"""
    
    missing, extra, match, nomatch = checkDoc(docName, expected, TARGET_ELEMENT, TARGET_ID_ATTRIB)
    print "  Checked targets in {0}. Missing: {1}. Extra: {2}. Matching: {3}. Not matching: {4}".format(docName, missing, extra, match, nomatch)
    return len(missing) == 0 and len(extra) == 0 and nomatch == 0


def printPass(passChecks):
    if passChecks:
        print "PASS"
    else:
        print "FAILURE"



def checkDoc(docName, expected, elementType, idAttrib):
    """Load and check an xml document against the expected values"""
    
    print "Checking document '{0}'".format(docName)
    xmldoc = getXmlDoc(docName)
    elements = xmldoc.getElementsByTagName(elementType)
    expectedValues = expected[docName]
    missing = listMissingElements(elements, idAttrib, expectedValues.keys())
    extra = listExtraElements(elements, idAttrib, expectedValues.keys())
    match, nomatch = elementsMatch(elements, idAttrib, expectedValues)
    
    return missing, extra, match, nomatch


def getXmlDoc(docName):
    """Loads an xml document and returns the document element"""
    
    f = open(docName, 'r')
    xmldoc = minidom.parse(f).documentElement
    f.close()
    return xmldoc


def listMissingElements(elements, idAttrib, expectedIds):
    """Checks that all the expected targets are present"""
    
    missingIds = []
    elemIds = []
    for element in elements:
        elemIds.append(element.getAttribute(idAttrib))
    for value in expectedIds:
        if value not in elemIds:
            missingIds.append(value)
    return missingIds
    

def listExtraElements(elements, idAttrib, expectedIds):
    """Checks that only the expected targets are present, with no extras"""
    
    foundExtras = []
    for element in elements:
        elemId = element.getAttribute(idAttrib)
        if elemId not in expectedIds:
            foundExtras.append(elemId)
    return foundExtras


def elementsMatch(elements, idAttrib, expected):
    """Checks that all given targets have the expected attributes"""
    
    matching = 0
    unmatching = 0
    
    for element in elements:
        resid = element.getAttribute(idAttrib)
        try:
            attribs = expected[resid]
            print "  Checking {0}".format(resid)
            if attributesMatch(element, attribs):
                matching += 1
            else:
                unmatching += 1
        except KeyError:
            pass # still want to check all the others if one fails
    return matching, unmatching

def attributesMatch(target, attribs):
    """Checks that the attributes of a target match the given map of attributes"""
    
    allMatch = True
    for attrib, expected in attribs.items():
        if attrib == 'content':
            actual = target.getElementsByTagName('content')[0].firstChild.nodeValue
        else:
            actual = target.getAttribute(attrib)
        if actual != expected:
            allMatch = False
            print "    Mismatch for {0}. Was '{1}' but expected '{2}'".format(attrib, actual, expected)
    return allMatch







if __name__ == '__main__':
    
    checkTargetDocs({})
    checkSourceDocs({})
