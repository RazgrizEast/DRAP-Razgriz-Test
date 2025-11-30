from enum import IntEnum
from typing import Optional, NamedTuple, Dict

from BaseClasses import Location, Region
from .Items import DRItem

class DRLocationCategory(IntEnum):
    SKIP = 0,
    EVENT = 1,


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
            "Rooftop"
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
    #Homeworld 1
    "Rooftop": [
        DRLocationData("Start the game", "Victory", DRLocationCategory.EVENT),
    ]
}

location_dictionary: Dict[str, DRLocationData] = {}
for location_table in location_tables.values():
    location_dictionary.update({location_data.name: location_data for location_data in location_table})
