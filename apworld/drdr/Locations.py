from enum import IntEnum
from typing import Optional, NamedTuple, Dict

from BaseClasses import Location, Region
from .Items import DRItem

class DRLocationCategory(IntEnum):
    SKIP = 0,
    EVENT = 1,
    SURVIVOR = 2,
    LEVEL_UP = 3,


class DRLocationData(NamedTuple):
    name: str
    default_item: str
    category: DRLocationCategory


class DRLocation(Location):
    game: str = "Dead Rising Deluxe Remaster"
    category: DRLocationCategory
    default_item_name: str

    def __init__(
        self,
        player: int,
        name: str,
        category: DRLocationCategory,
        default_item_name: str,
        address: Optional[int] = None,
        parent: Optional[Region] = None
    ):
        super().__init__(player, name, address, parent)
        self.default_item_name = default_item_name
        self.category = category
        self.name = name

    @staticmethod
    def get_name_to_id() -> dict:
        base_id = 1230000
        table_offset = 1000

        table_order = [
            "Rooftop",
            "Paradise Plaza",
            "Level Ups"
        ]

        output = {}
        for i, region_name in enumerate(table_order):
            if len(location_tables[region_name]) > table_offset:
                raise Exception("A location table has {} entries, that is more than {} entries (table #{})".format(len(location_tables[region_name]), table_offset, i))

            output.update({location_data.name: id for id, location_data in enumerate(location_tables[region_name], base_id + (table_offset * i))})

        return output

    def place_locked_item(self, item: DRItem):
        self.item = item
        self.locked = True
        item.location = self


# To ensure backwards compatibility, do not reorder locations or insert new ones in the middle of a list.
location_tables = {
    "Rooftop": [
        # Survivors rescued from Heliport
        DRLocationData("Rescue Jeff Meyer", "Orange Juice", DRLocationCategory.SURVIVOR),
        DRLocationData("Rescue Natalie Meyer", "Pizza", DRLocationCategory.SURVIVOR),
    ],

    "Paradise Plaza": [
        # Survivors rescued from Paradise Plaza
        DRLocationData("Rescue Greg Simpson", "Milk", DRLocationCategory.SURVIVOR),
        DRLocationData("Rescue Leah Stein", "Coffee Creamer", DRLocationCategory.SURVIVOR),
        DRLocationData("Rescue Kindell Johnson", "Wine", DRLocationCategory.SURVIVOR),
        DRLocationData("Rescue Beth Shrake", "Well Done Steak", DRLocationCategory.SURVIVOR),
        DRLocationData("Rescue Cheryl Jones", "Yogurt", DRLocationCategory.SURVIVOR),
        DRLocationData("Rescue Nathan Crabbe", "Apple", DRLocationCategory.SURVIVOR),
    ],

    "Level Ups": [
        # Level up rewards (50 levels)
        DRLocationData("Reach Level 2", "Pie", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 3", "Bread", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 4", "Orange Juice", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 5", "Pizza", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 6", "Milk", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 7", "Coffee Creamer", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 8", "Wine", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 9", "Well Done Steak", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 10", "Yogurt", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 11", "Apple", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 12", "Pie", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 13", "Bread", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 14", "Orange Juice", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 15", "Pizza", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 16", "Milk", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 17", "Coffee Creamer", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 18", "Wine", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 19", "Well Done Steak", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 20", "Yogurt", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 21", "Apple", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 22", "Pie", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 23", "Bread", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 24", "Orange Juice", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 25", "Pizza", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 26", "Milk", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 27", "Coffee Creamer", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 28", "Wine", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 29", "Well Done Steak", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 30", "Yogurt", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 31", "Apple", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 32", "Pie", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 33", "Bread", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 34", "Orange Juice", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 35", "Pizza", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 36", "Milk", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 37", "Coffee Creamer", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 38", "Wine", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 39", "Well Done Steak", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 40", "Yogurt", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 41", "Apple", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 42", "Pie", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 43", "Bread", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 44", "Orange Juice", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 45", "Pizza", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 46", "Milk", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 47", "Coffee Creamer", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 48", "Wine", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 49", "Well Done Steak", DRLocationCategory.LEVEL_UP),
        DRLocationData("Reach Level 50", "Victory", DRLocationCategory.LEVEL_UP),
    ]
}

location_dictionary: Dict[str, DRLocationData] = {}
for location_table in location_tables.values():
    location_dictionary.update({location_data.name: location_data for location_data in location_table})
