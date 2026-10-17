<?php
include '../include/db_con.php';
include '../func/helper.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error = '';
// Checked before `keyword`, since an advanced filter can carry a keyword too.
if (isset($_POST['advanced_filter'])) {
    $result = $helper->advancedFilterProperties($_POST);

    $response->status = 'Success';
    $response->data = $result;
} else if (isset($_POST['keyword'])) {
    $keyword = $_POST['keyword'];
    $result = $helper->searchProperty($keyword);

    $response->status = 'Success';
    $response->data = $result;
} else if (isset($_POST['filter'])) {
    $propertyType =   $_POST['propertyType'];
    $state = $_POST['state'];
    $community = $_POST['community'];
    $city = $_POST['city'];
    $result = $helper->filterProperty($propertyType, $state, $city, $community);

    $response->status = 'Success';
    $response->data = $result;
} else if (isset($_POST['search_product_keyword'])) {
    $productKeyword = $_POST['search_product_keyword'];

    $result = $helper->searchProducts($productKeyword);

    $response->status = 'Success';
    $response->data = $result;
} else {
    $response->status = 'unauthorized';
}

header('Content-type: application/json');
echo json_encode($response);
