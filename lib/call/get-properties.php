<?php
include '../include/db_con.php';
include '../func/helper.php';
require_once __DIR__ . '/cors.php';

$helper = new Helper;
$response = new stdClass;
$response->status = null;
$response->error = '';
if (isset($_POST['category'])) {
    $propertyType = $_POST['category'];
    $limit = $_POST['limit'];
    $properties = $helper->getProperties($propertyType, $limit);

    $response->status = 'Success';
    $response->data = $properties;
} else if (isset($_POST['property_videos_only'])) {
    $propertyType = $_POST['category'];
    $limit = $_POST['limit'];
    $properties = $helper->getPropertyVideosOnly($limit);

    $response->status = 'Success';
    $response->data = $properties;
} else if (isset($_POST['mixed'])) {
    $limit = $_POST['limit'];
    $properties = $helper->getMixedProperties($limit);
    $response->status = 'Success';
    $response->data = $properties;
} else if (isset($_POST['agentId'])) {
    $agentId = $_POST['agentId'];
    $limit = $_POST['limit'];
    $properties = $helper->getAgentProperties($agentId, $limit);
    $response->status = 'Success';
    $response->data = $properties;
} else if (isset($_POST['single_property'])) {
    $propertyId = $_POST['propertyId'];
    $property = $helper->getPropertyById($propertyId);
    $response->status = 'Success';
    $response->data = $property;
} else if (isset($_POST['get_products'])) {
    if (isset($_POST['related_products'])) {
        $limit = $_POST['limit'];
        $category = $_POST['related_products'];
        $id = $_POST['item_id'];
        $relatedProducts = $helper->getRelatedProducts($limit, $category, $id);

        $response->status = 'Success';
        $response->data = $relatedProducts;
    } else {
        $productType = $_POST['productType'];
        $limit = $_POST['limit'];
        $products = $helper->getProducts($limit, $productType);
        $response->status = 'Success';
        $response->data = $products;
    }
} else {
    $limit = isset($_POST['limit']) ? (int)$_POST['limit'] : 20;
    $uniqUserId = $_POST['userId'];
    $properties = $helper->getAllProperties($_POST['propertyType'], $limit, $uniqUserId);
    $response->status = 'Success';
    $response->data = $properties;
}

header('Content-type: application/json');
echo json_encode($response);
