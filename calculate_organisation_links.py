import glob
from lxml import etree
from lxml.etree import XMLParser
import os
import progressbar
import csv


def destroy_tree(tree):
    root = tree.getroot()

    node_tracker = {root: [0, None]}

    for node in root.iterdescendants():
        parent = node.getparent()
        node_tracker[node] = [node_tracker[parent][0] + 1, parent]

    node_tracker = sorted([(depth, parent, child) for child, (depth, parent)
                           in node_tracker.items()], key=lambda x: x[0], reverse=True)

    for _, parent, child in node_tracker:
        if parent is None:
            break
        parent.remove(child)

    del tree


large_parser = XMLParser(huge_tree=True)
parser = etree.XMLParser(remove_blank_text=True)

relational_org_mapping = {
    "receives activity funding from": "iati-activity/participating-org[@role='1' and (string-length(@ref) > 0)]/@ref | iati-activity/participating-org[@role='1' and (string-length(@ref) = 0)]/narrative/text()",
    "is accountable to": "iati-activity/participating-org[@role='2' and (string-length(@ref) > 0)]/@ref | iati-activity/participating-org[@role='2' and (string-length(@ref) = 0)]/narrative/text()",
    "has budget/direction managed by": "iati-activity/participating-org[@role='3' and (string-length(@ref) > 0)]/@ref | iati-activity/participating-org[@role='3' and (string-length(@ref) = 0)]/narrative/text()",
    "has project implemented by": "iati-activity/participating-org[@role='4' and (string-length(@ref) > 0)]/@ref | iati-activity/participating-org[@role='4' and (string-length(@ref) = 0)]/narrative/text()",
    "plans to receive transaction funding from": "iati-activity/planned-disbursement/provider-org[string-length(@ref) > 0]/@ref | iati-activity/planned-disbursement/provider-org[string-length(@ref) = 0]/narrative/text()",
    "plans to provide transaction funding to": "iati-activity/planned-disbursement/receiver-org[string-length(@ref) > 0]/@ref | iati-activity/planned-disbursement/receiver-org[string-length(@ref) = 0]/narrative/text()",
    "receives transaction funding from": "iati-activity/transaction/provider-org[string-length(@ref) > 0]/@ref | iati-activity/transaction/provider-org[string-length(@ref) = 0]/narrative/text()",
    "provides transaction funding to": "iati-activity/transaction/receiver-org[string-length(@ref) > 0]/@ref | iati-activity/transaction/receiver-org[string-length(@ref) = 0]/narrative/text()"
}

inverse_relation_mapping = {
    "receives activity funding from": "provides activity funding to",
    "is accountable to": "provides oversight for",
    "has budget/direction managed by": "manages the budget/direction for",
    "has project implemented by": "implements project for",
    "plans to receive transaction funding from": "plans to provide transaction funding to",
    "plans to provide transaction funding to": "plans to receive transaction funding from",
    "receives transaction funding from": "provides transaction funding to",
    "provides transaction funding to": "receives transaction funding from"
}


if __name__ == "__main__":
    output = set()

    xml_path = os.path.join("/home/alex/git/IATI-Registry-Refresher/data", '[!.]*', '*')
    xml_files = glob.glob(xml_path)
    bar = progressbar.ProgressBar()

    for xml_file in bar(xml_files):
        try:
            tree = etree.parse(xml_file, parser=large_parser)
        except etree.XMLSyntaxError:
            continue
        root = tree.getroot()
        
        reporting_orgs = list(set(root.xpath(
            "iati-activity/reporting-org[string-length(@ref) > 0]/@ref | iati-activity/reporting-org[string-length(@ref) = 0]/narrative/text()"
        )))

        for reporting_org in reporting_orgs:
            for relationship in relational_org_mapping:
                inverse_relation = inverse_relation_mapping[relationship]
                xpath_str = relational_org_mapping[relationship]
                relational_orgs = list(set(root.xpath(xpath_str)))
                for relational_org in relational_orgs:
                    if reporting_org != relational_org:
                        output_tup1 = (reporting_org, relationship, relational_org)
                        output.add(output_tup1)
                        output_tup2 = (relational_org, inverse_relation, reporting_org)
                        output.add(output_tup2)
        destroy_tree(tree)

    with open("organisation_links.csv", "w") as outfile:
        csv_out = csv.writer(outfile)
        csv_out.writerow(['Organisation 1', 'Relationship', 'Organisation 2'])
        csv_out.writerows(output)
        